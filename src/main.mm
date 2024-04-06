#include <iostream>
#include <AVFoundation/AVFoundation.h>
#include <CoreVideo/CoreVideo.h>

void transcode(const std::string& inputPath){

    NSURL* inputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:inputPath.c_str()]];
    NSError* error = Nil;

    CMTime startTimeValue = CMTimeMakeWithSeconds(1, 1000);
    CMTime durationValue = CMTimeMakeWithSeconds(0.3, 1000);

    AVAsset *srcAsset = [AVAsset assetWithURL:inputURL];
    AVAssetReader *srcAssetReader = [AVAssetReader assetReaderWithAsset:srcAsset error:&error];
    srcAssetReader.timeRange = CMTimeRangeMake(startTimeValue, durationValue);

    NSArray<AVAssetTrack*> *tracks = [srcAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *track = Nil;

    for (int i=0; i < [tracks count]; i++){
        AVMediaType t_type = tracks[i].mediaType;
        if ([t_type isEqual: @"vide"]){
            track = tracks[i];
            break;
        }
    }

    //Check here for which format to use -->
    //https://developer.apple.com/documentation/avfoundation/avassetreadertrackoutput?language=objc
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) };

    AVAssetReaderTrackOutput* assetReaderTrackOutput
            = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:outputSettings];

    assetReaderTrackOutput.alwaysCopiesSampleData = NO; //this is important
    [srcAssetReader addOutput:assetReaderTrackOutput];

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

        CMSampleBufferRef sampleBuffer = Nil;

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

                NSData *frameData = [NSData dataWithBytes:pixelData length:bytesPerRow * height];

                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

                // Release the sample buffer
                CFRelease(sampleBuffer);
                std::cout << bytesPerRow << std::endl;
            }
        }
    }
}


int main() {
    
    std::string inputFile = "/Users/juanaboites/dev/postlink/avf-transcode-cpp/src/videos/large_prores.mov";
    double startTime = 1.0; // Start time in seconds
    double duration = 1.0; // Duration in seconds

    transcode(inputFile);

    std::cout << "done" << std::endl;

    return 0;
}