//
// Created by Juan Aboites on 4/8/24.
//

#import "VideoTranscoder.h"
#include <iostream>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

@implementation VideoTranscoder

    NSString* currentPath = @"Current Path";
    CMTime currentPresentationTimestamp;
    std::unordered_map<CMTimeValue, NSData*> transcodeBuffer;

    AVAssetReader* reader;
    AVAssetReaderOutput* readerOutput;
    AVAssetWriterInput* writerInput;
    AVAssetWriterInputPixelBufferAdaptor* adaptor;

    + (NSString*) getCurrentPath{
        return currentPath;
    }

    + (NSData*) getFrame:(int32_t)ts {
        auto itemIter = transcodeBuffer.find(ts);
        if (itemIter != transcodeBuffer.end()){
            NSData* frame = transcodeBuffer[ts];
            transcodeBuffer.erase(ts); //don't think I need to release anything here?
            return frame;
        }

        else return nil;
    }

    + (BOOL) setNewSource:(std::string&)path secondArg:(float)startTime{

        currentPath = [NSString stringWithUTF8String:path.c_str()];
        NSURL* url = [NSURL fileURLWithPath:currentPath];
        AVAsset* asset = [AVAsset assetWithURL:url];

        NSError *error = nil;
        reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
        if (error) {
            return false;
        }

        //Not sure about the timescale here
        CMTime start = CMTimeMakeWithSeconds(startTime, 1000);
        currentPresentationTimestamp = start;

        reader.timeRange = CMTimeRangeMake(start, asset.duration);

        NSArray<AVAssetTrack*> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *track = [tracks objectAtIndex:0];

        //select most appropriate one based on filename extension See here for more info
        //https://developer.apple.com/documentation/avfoundation/avassetreadertrackoutput?language=objc
        NSDictionary* readerOutputSettings  = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) };

        readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:readerOutputSettings];
        readerOutput.alwaysCopiesSampleData = NO; //this is important
        [reader addOutput:readerOutput];

        //Set up writer
        NSDictionary *writerOutputSettings = @{
                AVVideoCodecKey: AVVideoCodecTypeH264,
                AVVideoWidthKey: @(960),
                AVVideoHeightKey: @(540),
                AVVideoCompressionPropertiesKey: @{
                        AVVideoAverageBitRateKey: @(400000)
                }
        };

        writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:writerOutputSettings];
        writerInput.expectsMediaDataInRealTime = YES;
        adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];

        //Start reading
        BOOL success = [reader startReading];
        return success;

    }

    + (BOOL) decodeBatch{

        int loopNum = 0;
        CMSampleBufferRef sampleBuffer = Nil;

        while (loopNum < 10 && (sampleBuffer = [readerOutput copyNextSampleBuffer])){

            CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

            if (pixelBuffer){

                CMTime ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

                if ([writerInput isReadyForMoreMediaData]) {
                    [adaptor appendPixelBuffer:pixelBuffer withPresentationTime:ts];
                }

                CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                void *pixelBufferPtr = CVPixelBufferGetBaseAddress(pixelBuffer);

                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
                size_t height = CVPixelBufferGetHeight(pixelBuffer);

                NSData *frameData = [NSData dataWithBytes:pixelBufferPtr
                                                   length:bytesPerRow * height];

                transcodeBuffer[ts.value] = frameData;

                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                CFRelease(sampleBuffer);

                //NSLog(@"Frame Transcoded");
                std::cout << "Frame Transcoded" << std::endl;

                ++loopNum;
            }

        }

        return true;
    }

@end