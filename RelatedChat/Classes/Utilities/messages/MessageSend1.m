//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MessageSend1.h"

@implementation MessageSend1

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)send:(NSString *)groupId text:(NSString *)text video:(NSURL *)video picture:(UIImage *)picture audio:(NSString *)audio view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = [FObject objectWithPath:FMESSAGE_PATH Subpath:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_GROUPID] = groupId;
	message[FMESSAGE_SENDERID] = [FUser currentId];
	message[FMESSAGE_SENDERNAME] = [FUser fullname];
	message[FMESSAGE_SENDERINITIALS] = [FUser initials];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_PICTURE] = @"";
	message[FMESSAGE_PICTURE_WIDTH] = @0;
	message[FMESSAGE_PICTURE_HEIGHT] = @0;
	message[FMESSAGE_PICTURE_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_VIDEO] = @"";
	message[FMESSAGE_VIDEO_DURATION] = @0;
	message[FMESSAGE_VIDEO_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_AUDIO] = @"";
	message[FMESSAGE_AUDIO_DURATION] = @0;
	message[FMESSAGE_AUDIO_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_LATITUDE] = @0;
	message[FMESSAGE_LONGITUDE] = @0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_STATUS] = TEXT_SENT;
	message[FMESSAGE_ISDELETED] = @NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (text != nil)	[self sendTextMessage:message text:text];
	if (picture != nil)	[self sendPictureMessage:message picture:picture view:view];
	if (video != nil)	[self sendVideoMessage:message video:video view:view];
	if (audio != nil)	[self sendAudioMessage:message audio:audio view:view];
	if ((text == nil) && (picture == nil) && (video == nil) && (audio == nil)) [self sendLoactionMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendTextMessage:(FObject *)message text:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	message[FMESSAGE_TEXT] = text;
	message[FMESSAGE_TYPE] = [Emoji isEmoji:text] ? MESSAGE_EMOJI : MESSAGE_TEXT;
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendPictureMessage:(FObject *)message picture:(UIImage *)picture view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSData *dataPicture = UIImageJPEGRepresentation(picture, 0.6);
	NSData *cryptedPicture = [Cryptor encryptData:dataPicture groupId:message[FMESSAGE_GROUPID]];
	NSString *md5Picture = [Checksum md5HashOfData:cryptedPicture];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_image", @"jpg")];
	FIRStorageUploadTask *task = [reference putData:cryptedPicture metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		[task removeAllObservers];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileImage:link];
			[dataPicture writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_PICTURE] = link;
			message[FMESSAGE_PICTURE_WIDTH] = @((NSInteger) picture.size.width);
			message[FMESSAGE_PICTURE_HEIGHT] = @((NSInteger) picture.size.height);
			message[FMESSAGE_PICTURE_MD5] = md5Picture;
			message[FMESSAGE_TEXT] = @"[Picture message]";
			message[FMESSAGE_TYPE] = MESSAGE_PICTURE;
			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendVideoMessage:(FObject *)message video:(NSURL *)video view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSNumber *duration = [Video duration:video.path];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataVideo = [NSData dataWithContentsOfFile:video.path];
	NSData *cryptedVideo = [Cryptor encryptData:dataVideo groupId:message[FMESSAGE_GROUPID]];
	NSString *md5Video = [Checksum md5HashOfData:cryptedVideo];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_video", @"mp4")];
	FIRStorageUploadTask *task = [reference putData:cryptedVideo metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		[task removeAllObservers];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileVideo:link];
			[dataVideo writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_VIDEO] = link;
			message[FMESSAGE_VIDEO_DURATION] = duration;
			message[FMESSAGE_VIDEO_MD5] = md5Video;
			message[FMESSAGE_TEXT] = @"[Video message]";
			message[FMESSAGE_TYPE] = MESSAGE_VIDEO;
			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendAudioMessage:(FObject *)message audio:(NSString *)audio view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSNumber *duration = [Audio duration:audio];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataAudio = [NSData dataWithContentsOfFile:audio];
	NSData *cryptedAudio = [Cryptor encryptData:dataAudio groupId:message[FMESSAGE_GROUPID]];
	NSString *md5Audio = [Checksum md5HashOfData:cryptedAudio];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_audio", @"m4a")];
	FIRStorageUploadTask *task = [reference putData:cryptedAudio metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		[task removeAllObservers];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileAudio:link];
			[dataAudio writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_AUDIO] = link;
			message[FMESSAGE_AUDIO_DURATION] = duration;
			message[FMESSAGE_AUDIO_MD5] = md5Audio;
			message[FMESSAGE_TEXT] = @"[Audio message]";
			message[FMESSAGE_TYPE] = MESSAGE_AUDIO;
			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendLoactionMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	message[FMESSAGE_LATITUDE] = @([Location latitude]);
	message[FMESSAGE_LONGITUDE] = @([Location longitude]);
	message[FMESSAGE_TEXT] = @"[Location message]";
	message[FMESSAGE_TYPE] = MESSAGE_LOCATION;
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	message[FMESSAGE_TEXT] = [Cryptor encryptText:message[FMESSAGE_TEXT] groupId:message[FMESSAGE_GROUPID]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[message saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[JSQSystemSoundPlayer jsq_playMessageSentSound];
			[Recent updateLastMessage:message];
			SendPushNotification1(message);
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
}

@end

