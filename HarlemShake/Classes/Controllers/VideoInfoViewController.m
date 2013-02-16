//
//  VideoInfoViewController.m
//  Harlem Shake
//
//  Created by Jason Fieldman on 2/12/13.
//  Copyright (c) 2013 Jason Fieldman. All rights reserved.
//

#import "VideoInfoViewController.h"
#import "TextEditViewController.h"
#import "RecordingOptionsViewController.h"
#import "ClipRecorderViewController.h"

#import "UITableViewCellEx.h"
#import "ClipControlTableViewCell.h"

#define kCellTag_Title            1
#define kCellTag_Description      2
#define kCellTag_RecordingOptions 3
#define kCellTag_EncodeVideo      4
#define kCellTag_Watch            5
#define kCellTag_Share            6


@implementation VideoInfoViewController


- (id) init {
	if ((self = [super init])) {
		
		/* View title */
		self.title = @"Video Info";
		
		/* Initialize the main view */
		self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
		self.view.backgroundColor = [UIColor clearColor];
		self.view.autoresizesSubviews = YES;
		self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		
		/* Initialize the table */
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100) style:UITableViewStyleGrouped];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		_tableView.backgroundColor = [UIColor clearColor];
		_tableView.delegate = self;
		_tableView.dataSource = self;
		_tableView.scrollEnabled = NO;
		[self.view addSubview:_tableView];
		
		/* Notifications */
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(moviePlayBackDidFinish:)
													 name:MPMoviePlayerWillExitFullscreenNotification
												   object:nil];
		
		_audioWarning = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, 300, 20)];
		_audioWarning.font = [UIFont systemFontOfSize:13];
		_audioWarning.text = @"Clip is silent.  Audio is added when encoded.";
		_audioWarning.textColor = [UIColor whiteColor];
		_audioWarning.backgroundColor = [UIColor blackColor];
		_audioWarning.alpha = 0.5;
		_audioWarning.textAlignment = NSTextAlignmentCenter;
		
		
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) viewWillAppear:(BOOL)animated {
	if (!_videoId) return;
	[self initializeTableCells];
	[_tableView reloadData];
}


/* Movie playback */

- (void) moviePlayBackDidFinish:(NSNotification*)notification {
	[_audioWarning removeFromSuperview];
}


/* Table Cells */

- (void) initializeTableCells {
	
	_tableCells = [NSMutableArray array];
	
	/* Basic settings */
	
	{
		NSMutableArray *currentSection = [NSMutableArray array];
		
		{
			UITableViewCellEx *cell = [[UITableViewCellEx alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"Title";
			cell.detailTextLabel.text = [[[VideoModel sharedInstance] videoDic:_videoId] objectForKey:@"title"];
			if (![cell.detailTextLabel.text length]) cell.detailTextLabel.text = @"Untitled";
			cell.tag = kCellTag_Title;
			cell.shouldHighlight = YES;
			[currentSection addObject:cell];
		}
		
		{
			UITableViewCellEx *cell = [[UITableViewCellEx alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"Description";
			cell.detailTextLabel.text = [[[VideoModel sharedInstance] videoDic:_videoId] objectForKey:@"description"];
			if (![cell.detailTextLabel.text length]) cell.detailTextLabel.text = @"None";
			cell.tag = kCellTag_Description;
			cell.shouldHighlight = YES;
			[currentSection addObject:cell];
		}
		
		{
			UITableViewCellEx *cell = [[UITableViewCellEx alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"Recording Options";
			cell.tag = kCellTag_RecordingOptions;
			cell.shouldHighlight = YES;
			[currentSection addObject:cell];
		}
			
		[_tableCells addObject:currentSection];
	}
	
	/* Clip info */
	
	{
		NSMutableArray *currentSection = [NSMutableArray array];
		
		{
			ClipControlTableViewCell *cell = [[ClipControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
			cell.videoId = _videoId;
			cell.shouldHighlight = NO;
			cell.controlDelegate = self;
			[currentSection addObject:cell];
		}
				
		[_tableCells addObject:currentSection];
	}
	
	/* Dealing with the final video */
	
	{
		NSMutableArray *currentSection = [NSMutableArray array];
	
		if (_forceExistanceOfVideo || [[VideoModel sharedInstance] fullVideoExistsForVideo:_videoId]) {
			_forceExistanceOfVideo = NO;
			
			/* This is what happens if the full video is already encoded! */
			
			{
				UITableViewCellEx *cell = [[UITableViewCellEx alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"Watch Full Version";
				cell.tag = kCellTag_Watch;
				cell.shouldHighlight = YES;
				[currentSection addObject:cell];
			}

			{
				UITableViewCellEx *cell = [[UITableViewCellEx alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"Share!";
				cell.tag = kCellTag_Share;
				cell.shouldHighlight = YES;
				[currentSection addObject:cell];
			}

			
		} else {
			
			/* Video is not encoded. Can we encode yet? */
			
			if ([[VideoModel sharedInstance] clipExistsforVideo:_videoId beforeDrop:YES] && [[VideoModel sharedInstance] clipExistsforVideo:_videoId beforeDrop:NO]) {
				
				/* Both clips exist, so we can encode it */
				UITableViewCellEx *cell = [[UITableViewCellEx alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"Encode Video!";
				cell.tag = kCellTag_EncodeVideo;
				cell.shouldHighlight = YES;
				[currentSection addObject:cell];
				
			} else {
				
				/* Nope, a clip is missing */
				UITableViewCellEx *cell = [[UITableViewCellEx alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
				cell.sectionFooterText = @"Cannot encode the video until both \"Before Drop\" and \"After Drop\" clips have been recorded.";
				[currentSection addObject:cell];
				
			}
			
		}
		
		[_tableCells addObject:currentSection];
	}
	
}


- (void) setVideoId:(VideoID_t)videoId {
	_videoId = videoId;
}

- (void)               video: (NSString *) videoPath
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo {
	NSLog(@"SAVED [error: %@]", error);
}

#pragma mark Encoding

- (void) encodeMovie {
	EXLog(RENDER, INFO, @"Starting to encode");
	
	AVMutableComposition *mixComposition = [AVMutableComposition composition];
	
	/* Get assets */
	
	NSString *audioPath1 = [NSString stringWithFormat:@"%@/part1.m4a", [[NSBundle mainBundle] resourcePath]];
	NSURL *audioUrl1 = [NSURL fileURLWithPath:audioPath1];
	AVURLAsset *audioasset1 = [[AVURLAsset alloc] initWithURL:audioUrl1 options:nil];
	
	NSString *audioPath2 = [NSString stringWithFormat:@"%@/part2.m4a", [[NSBundle mainBundle] resourcePath]];
	NSURL *audioUrl2 = [NSURL fileURLWithPath:audioPath2];
	AVURLAsset *audioasset2 = [[AVURLAsset alloc] initWithURL:audioUrl2 options:nil];
	
	NSString *videoPath1 = [[VideoModel sharedInstance] pathToClipForVideo:_videoId beforeDrop:YES];
	NSURL *videoUrl1 = [NSURL fileURLWithPath:videoPath1];
	AVURLAsset *videoasset1 = [[AVURLAsset alloc] initWithURL:videoUrl1 options:nil];
	
	NSString *videoPath2 = [[VideoModel sharedInstance] pathToClipForVideo:_videoId beforeDrop:NO];
	NSURL *videoUrl2 = [NSURL fileURLWithPath:videoPath2];
	AVURLAsset *videoasset2 = [[AVURLAsset alloc] initWithURL:videoUrl2 options:nil];
	
	/* Output path */
	
	NSString *outputPath = [[VideoModel sharedInstance] pathToFullVideoTemp:_videoId];
	NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
	}

	/* Create composition */
	
	NSError *error;
	CMTime nextClipStartTime = kCMTimeZero;
	
	NSMutableArray *instructions = [NSMutableArray array];
	
	AVMutableCompositionTrack *compositionTrackB = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	AVAssetTrack *clipVideoTrackB = [[videoasset1 tracksWithMediaType:AVMediaTypeVideo] lastObject];
	[compositionTrackB insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoasset1.duration)  ofTrack:clipVideoTrackB atTime:kCMTimeZero error:&error];
	if (error) { NSLog(@"ERRORA: %@", error); }
	
	{
		// create a layer instruction at the start of this clip to apply the preferred transform to correct orientation issues
		AVMutableVideoCompositionLayerInstruction *instruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrackB];
		[instruction setTransform:videoasset1.preferredTransform atTime:kCMTimeZero];
		[instruction setOpacity:1 atTime:kCMTimeZero];
		
		// create the composition instructions for the range of this clip
		AVMutableVideoCompositionInstruction * videoTrackInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		videoTrackInstruction.timeRange = CMTimeRangeMake(nextClipStartTime, videoasset1.duration);
		videoTrackInstruction.layerInstructions = @[instruction];
		[instructions addObject:videoTrackInstruction];
	}
	
	nextClipStartTime = CMTimeAdd(nextClipStartTime, videoasset1.duration);
	
	AVAssetTrack *clipVideoTrackB2 = [[videoasset2 tracksWithMediaType:AVMediaTypeVideo] lastObject];
	[compositionTrackB insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoasset2.duration)  ofTrack:clipVideoTrackB2 atTime:nextClipStartTime error:&error];
	if (error) { NSLog(@"ERRORB: %@", error); }
	
	{
		// create a layer instruction at the start of this clip to apply the preferred transform to correct orientation issues
		AVMutableVideoCompositionLayerInstruction *instruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrackB2];
		[instruction setTransform:videoasset2.preferredTransform atTime:kCMTimeZero];
		[instruction setOpacity:1 atTime:kCMTimeZero];
		
		// create the composition instructions for the range of this clip
		AVMutableVideoCompositionInstruction * videoTrackInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		CMTime fuck = CMTimeAdd(videoasset2.duration, videoasset2.duration);
		videoTrackInstruction.timeRange = CMTimeRangeMake(nextClipStartTime, fuck);
		videoTrackInstruction.layerInstructions = @[instruction];
		[instructions addObject:videoTrackInstruction];
	}
	
	CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
	//    CGAffineTransform rotateTranslate = CGAffineTransformTranslate(rotationTransform,360,0);
    compositionTrackB.preferredTransform = rotationTransform;
	
	// Audio
	
	AVMutableCompositionTrack *compositionTrackA = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	AVAssetTrack *clipAudioTrackA = [[audioasset1 tracksWithMediaType:AVMediaTypeAudio] lastObject];
	[compositionTrackA insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioasset1.duration)  ofTrack:clipAudioTrackA atTime:kCMTimeZero error:nil];
	
	AVMutableCompositionTrack *compositionTrackA2 = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	AVAssetTrack *clipAudioTrackA2 = [[audioasset2 tracksWithMediaType:AVMediaTypeAudio] lastObject];
	[compositionTrackA2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioasset2.duration)  ofTrack:clipAudioTrackA2 atTime:audioasset1.duration error:nil];
	
	/* Export session */

	AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
	videoComposition.instructions = instructions;
	videoComposition.renderScale = 1;
	NSLog(@"fr: %f %f %f", (float) clipVideoTrackB.naturalTimeScale, clipVideoTrackB.naturalSize.width, clipVideoTrackB.naturalSize.height);
	
	CGSize size = [clipVideoTrackB naturalSize];
	NSLog(@"size.width = %f size.height = %f", size.width, size.height);
	CGAffineTransform txf = [clipVideoTrackB preferredTransform];
	NSLog(@"txf.a = %f txf.b = %f txf.c = %f txf.d = %f txf.tx = %f txf.ty = %f", txf.a, txf.b, txf.c, txf.d, txf.tx, txf.ty);
	
	videoComposition.frameDuration = CMTimeMake(1, compositionTrackB.naturalTimeScale);
	videoComposition.renderSize = compositionTrackB.naturalSize;
	
	_exportSession =[[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
	_exportSession.outputFileType = AVFileTypeMPEG4;
	_exportSession.outputURL = outputURL;
	_exportSession.videoComposition = videoComposition;
	
	{
		AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
		//videoComposition.renderSize = CGSizeMake(320, 240);
		
		if (txf.a == 0) {
			videoComposition.renderSize = CGSizeMake( compositionTrackB.naturalSize.height, compositionTrackB.naturalSize.width);
		} else {
			videoComposition.renderSize = compositionTrackB.naturalSize;
		}
		videoComposition.frameDuration = CMTimeMake(1, 30);
		
		AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
		
		AVMutableVideoCompositionLayerInstruction* rotator = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:[[videoasset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]];
		//CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation( 0,-320);
		//CGAffineTransform rotateBy90Degrees = CGAffineTransformMakeRotation( M_PI_2);
		//CGAffineTransform shrinkWidth = CGAffineTransformMakeScale(0.66, 1); // needed because Apple does a "stretch" by default - really, we should find and undo apple's stretch - I suspect it'll be a CALayer defaultTransform, or UIView property causing this
		//CGAffineTransform finalTransform = CGAffineTransformConcat( shrinkWidth, CGAffineTransformConcat(translateToCenter, rotateBy90Degrees) );
		//[rotator setTransform:finalTransform atTime:kCMTimeZero];
		[rotator setTransform:txf atTime:kCMTimeZero];
		
		instruction.layerInstructions = [NSArray arrayWithObject: rotator];
		videoComposition.instructions = [NSArray arrayWithObject: instruction];
		
		_exportSession.videoComposition = videoComposition;
	}
	
	/* Start status timer */

	[_exportStatusTimer invalidate];
	_exportStatusTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(handleExportStatusTimer:) userInfo:nil repeats:YES];
	
	/* Begin */
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[_exportSession exportAsynchronouslyWithCompletionHandler:^{
		
		switch ([_exportSession status]) {
			case AVAssetExportSessionStatusFailed:
				EXLog(RENDER, ERR, @"Export failed: %@", [[_exportSession error] localizedDescription]);
				break;
			case AVAssetExportSessionStatusCancelled:
				EXLog(RENDER, ERR, @"Export canceled");
				break;
			case AVAssetExportSessionStatusCompleted:
				EXLog(RENDER, INFO, @"Export done");
				[SVProgressHUD showProgress:1 status:@"Finishing" maskType:SVProgressHUDMaskTypeGradient];
				
				/* Move the file over */
				[[NSFileManager defaultManager] removeItemAtPath:[[VideoModel sharedInstance] pathToFullVideo:_videoId] error:nil];
				[[NSFileManager defaultManager] moveItemAtPath:[[VideoModel sharedInstance] pathToFullVideoTemp:_videoId] toPath:[[VideoModel sharedInstance] pathToFullVideo:_videoId] error:nil];
				_forceExistanceOfVideo = YES;
				
				break;
		}
		
		[_exportStatusTimer invalidate];
		_exportStatusTimer = nil;
		
		[SVProgressHUD dismiss];
		[self initializeTableCells];
		[_tableView reloadData];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		
	}];
	
	
}

- (void) handleExportStatusTimer:(NSTimer*)timer {
	[SVProgressHUD showProgress:_exportSession.progress status:@"Encoding" maskType:SVProgressHUDMaskTypeGradient];
}

#pragma mark ClipControlTableViewCellDelegate methods

- (void) clipControlPressedWatch:(BOOL)before {
	NSURL *movie = [NSURL fileURLWithPath:[[VideoModel sharedInstance] pathToClipForVideo:_videoId beforeDrop:before]];
	_moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movie];
	[_moviePlayer prepareToPlay];
	[self.view addSubview:_moviePlayer.view];
	[_moviePlayer setFullscreen:YES animated:YES];
	[_moviePlayer play];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		UIWindow *window = [UIApplication sharedApplication].keyWindow;
		if (!window) {
			window = [[UIApplication sharedApplication].windows objectAtIndex:0];
		}
		NSLog(@"window: %@", window);
		[[[window subviews] objectAtIndex:0] addSubview:_audioWarning];
	});
	
	
	
}

- (void) clipControlPressedRecord:(BOOL)before {
	ClipRecorderViewController *crvc = [[ClipRecorderViewController alloc] initWithVideo:_videoId before:before];
	[self presentViewController:crvc animated:YES completion:nil];
}


#pragma mark UITableViewDelegate methods

- (int) numberOfSectionsInTableView:(UITableView *)tableView {
	return [_tableCells count];
}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[_tableCells objectAtIndex:section] count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[_tableCells objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UITableViewCell *cell = [self tableView:_tableView cellForRowAtIndexPath:indexPath];
	switch (cell.tag) {
		case kCellTag_Title: {
			TextEditViewController *evc = [[TextEditViewController alloc] init];
			evc.title = @"Title";
			evc.videoId = _videoId;
			evc.attributeName = @"title";
			[self.navigationController pushViewController:evc animated:YES];
		}
		break;
			
		case kCellTag_Description: {
			TextEditViewController *evc = [[TextEditViewController alloc] init];
			evc.title = @"Description";
			evc.videoId = _videoId;
			evc.attributeName = @"description";
			[self.navigationController pushViewController:evc animated:YES];
		}
		break;
			
		case kCellTag_RecordingOptions: {
			RecordingOptionsViewController *rovc = [[RecordingOptionsViewController alloc] init];
			[self.navigationController pushViewController:rovc animated:YES];
		}
		break;
			
		case kCellTag_EncodeVideo: {
			[self encodeMovie];
		}
		break;
			
		case kCellTag_Watch: {
			NSURL *movie = [NSURL fileURLWithPath:[[VideoModel sharedInstance] pathToFullVideo:_videoId]];
			_moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movie];
			[_moviePlayer prepareToPlay];
			[self.view addSubview:_moviePlayer.view];
			[_moviePlayer setFullscreen:YES animated:YES];
			[_moviePlayer play];
		}
		break;
			
		case kCellTag_Share: {
			NSURL *url = [NSURL fileURLWithPath:[[VideoModel sharedInstance] pathToFullVideo:_videoId]];
			UISaveVideoAtPathToSavedPhotosAlbum([url relativePath], self,@selector(video:didFinishSavingWithError:contextInfo:), nil);
		}
		break;
			
		default:
			break;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCellEx *cell = [[_tableCells objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	return cell.cellHeight;
}

@end
