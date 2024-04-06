#include <iostream>
#include <AVFoundation/AVFoundation.h>
#include <CoreVideo/CoreVideo.h>

void transcode(const std::string& inputPath){

    NSURL* inputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:inputPath.c_str()]];
    NSError* error = Nil;

    // Create an AVAsset with a URL pointing at a local asset. Create an AVAssetReader for the asset
    AVAsset *srcAsset = [AVAsset assetWithURL:inputURL];
    AVAssetReader *srcAssetReader = [AVAssetReader assetReaderWithAsset:srcAsset
                                                               error:&error];

    // Copy the array of video tracks from the source movie
    NSArray<AVAssetTrack*>  *tracks = [srcAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *track = [tracks objectAtIndex:0]; //just gets the first track, will have to modify this

    //Create the asset reader track output for this video track, requesting ‘y416’ output.
    //Not sure what to set here,
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey :
                                      @(kCVPixelFormatType_4444AYpCbCr16) };

    AVAssetReaderTrackOutput* assetReaderTrackOutput
            = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:outputSettings];

    assetReaderTrackOutput.alwaysCopiesSampleData = NO; //this is important
    [srcAssetReader addOutput:assetReaderTrackOutput]; //Connect the AVAssetReaderTrackOutput to the AVAssetReader

    //Set up the writer
    NSDictionary *writerSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey: @(960),
            AVVideoHeightKey: @(540),
            AVVideoCompressionPropertiesKey: @{
                    AVVideoAverageBitRateKey: @(400000)
            }
    };
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:writerSettings];
    writerInput.expectsMediaDataInRealTime = YES;
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];

    BOOL success = [srcAssetReader startReading];

    if (success) {

        CMSampleBufferRef sampleBuffer = NULL;
        // output is a AVAssetReaderOutput
        while ((sampleBuffer = [assetReaderTrackOutput copyNextSampleBuffer]))
        {
            CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

            if (pixelBuffer){

                if ([writerInput isReadyForMoreMediaData]) {
                    [adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                }

                CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
                size_t height = CVPixelBufferGetHeight(pixelBuffer);

                // Create a data object with the pixel data
                NSData *frameData = [NSData dataWithBytes:pixelData length:bytesPerRow * height];

                // Send the frame data across the network
                // ...

                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

                // Release the sample buffer
                CFRelease(sampleBuffer);
                std::cout << "transcoded frame" << std::endl;
            }
        }
    }
}


int main() {
    
    std::string inputFile = "/Users/juanaboites/dev/postlink/avf-transcode-cpp/src/videos/large_prores.mov";
    std::string outputFile = "./videos/smp.mov";
    double startTime = 1.0; // Start time in seconds
    double duration = 1.0; // Duration in seconds

    transcode(inputFile);

    std::cout << "done" << std::endl;

    return 0;
}