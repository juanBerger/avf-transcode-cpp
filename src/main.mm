#include <iostream>
#include <AVFoundation/AVFoundation.h>

//void transcodeVideoRange(const std::string& inputFilePath, const std::string& outputFilePath, double startTime, double duration) {
//
//    NSURL* inputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:inputFilePath.c_str()]];
//    NSURL* outputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:outputFilePath.c_str()]];
//
//    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
//    AVAssetExportSession* exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
//
//    CMTime startTimeValue = CMTimeMakeWithSeconds(startTime, 1000);
//    CMTime durationValue = CMTimeMakeWithSeconds(duration, 1000);
//    CMTimeRange timeRange = CMTimeRangeMake(startTimeValue, durationValue);
//
//    exportSession.outputURL = outputURL;
//    exportSession.outputFileType = AVFileTypeQuickTimeMovie; // For QuickTime output format
//    //exportSession.outputFileType = AVFileTypeMPEG4; // For MPEG-4 output format
//    exportSession.timeRange = timeRange;
//
//    [exportSession exportAsynchronouslyWithCompletionHandler:^{
//        switch (exportSession.status) {
//            case AVAssetExportSessionStatusCompleted:
//                // Transcoding completed successfully
//                break;
//            case AVAssetExportSessionStatusFailed:
//                // Transcoding failed
//                break;
//            case AVAssetExportSessionStatusCancelled:
//                // Transcoding was canceled
//                break;
//            default:
//                break;
//        }
//    }];
//}

void transcode(const std::string& inputPath){

    NSURL* inputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:inputPath.c_str()]];
    NSError* error;

    // Create an AVAsset with a URL pointing at a local asset
    AVAsset *sourceMovieAsset = [AVAsset assetWithURL:inputURL];

    // Create an AVAssetReader for the asset
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:sourceMovieAsset
                                                               error:&error];

    // Copy the array of video tracks from the source movie
    NSArray<AVAssetTrack*>  *tracks = [sourceMovieAsset tracksWithMediaType:AVMediaTypeVideo];

    // Get the first video track
    AVAssetTrack *track = [tracks objectAtIndex:0];

    // Create the asset reader track output for this video track, requesting ‘y416’ output
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey :
                                      @(kCVPixelFormatType_4444AYpCbCr16) };

    AVAssetReaderTrackOutput* assetReaderTrackOutput
            = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track
                                                         outputSettings:outputSettings];

    // Set the property to instruct the track output to return the samples
    // without copying them
    assetReaderTrackOutput.alwaysCopiesSampleData = NO;

    // Connect the AVAssetReaderTrackOutput to the AVAssetReader
    [assetReader addOutput:assetReaderTrackOutput];

    BOOL success = [assetReader startReading];
    std::cout << success << std::endl;

//    if (success) {
//        CMSampleBufferRef sampleBuffer = NULL;
//
//        // output is a AVAssetReaderOutput
//        while ((sampleBuffer = [output copyNextSampleBuffer]))
//        {
//            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//            if (imageBuffer)
//            {
//
//                // Use the image buffer here
//                // if imageBuffer is NULL, this is likely a marker sampleBuffer
//            }
//        }
//    }

}


int main() {
    
    std::string inputFile = "./videos/small_prores.mov";
    std::string outputFile = "./videos/smp.mov";
    double startTime = 1.0; // Start time in seconds
    double duration = 1.0; // Duration in seconds

    transcode(inputFile);

    std::cout << "done" << std::endl;

    return 0;
}