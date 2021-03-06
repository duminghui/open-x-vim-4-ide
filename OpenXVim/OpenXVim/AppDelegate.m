//
//  AppDelegate.m
//  OpenXVim
//
//  Created by dumh on 16/8/22.
//  Copyright © 2016年 dumh. All rights reserved.
//

#import "AppDelegate.h"
#import "AppSettings.h"
#import "StatusBarMenu.h"

@interface AppDelegate (){
  NSString * cmdPath;
  AppSettings * settings;
}

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize statusItem;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  
  self.statusItem = [[StatusBarMenu alloc]init].statusItem;
  
  cmdPath = [[NSBundle mainBundle]pathForResource:@"openxvim" ofType:@""];
  
  settings = [AppSettings sharedInstance];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
  [[NSAppleEventManager sharedAppleEventManager]
   setEventHandler:self andSelector:@selector(handleOpenDocumentsEvent:withReplyEvent:)
   forEventClass:kCoreEventClass andEventID:kAEOpenDocuments];
  //  [[NSAppleEventManager sharedAppleEventManager]
  //   setEventHandler:self andSelector:@selector(handleReopenApplicationEvent:withReplyEvent:)
  //   forEventClass:kCoreEventClass andEventID:kAEReopenApplication];
}


//- (void)handleReopenApplicationEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
//  NSAppleEventDescriptor* fileListDescriptor = [replyEvent paramDescriptorForKeyword:keyDirectObject];
//  NSInteger numberOfFiles = [fileListDescriptor numberOfItems];
//  NSLog(@"filenumber:%ld",(long)numberOfFiles);
//  NSString* filepath = [[replyEvent descriptorForKeyword:keyDirectObject] stringValue];
//  filepath = [filepath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//  filepath = [filepath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
//  NSLog(@"filepath:%@",filepath);
//  //  keyDirectObject               = '----',
//  //  keyErrorNumber                = 'errn',
//  //  keyErrorString                = 'errs',
//  //  keyProcessSerialNumber        = 'psn ', /* Keywords for special handlers */
//  //  keyPreDispatch                = 'phac', /* preHandler accessor call */
//  //  keySelectProc                 = 'selh', /* more selector call */
//  //  /* Keyword for recording */
//  //  keyAERecorderCount            = 'recr', /* available only in vers 1.0.1 and greater */
//  //  /* Keyword for version information */
//  //  keyAEVersion                  = 'vers' /* available only in vers 1.0.1 and greater */;
//  NSLog(@"keyDirectObject:%@",[[event paramDescriptorForKeyword:keyDirectObject]description]);
//  NSLog(@"keyErrorNumber:%@",[[event paramDescriptorForKeyword:keyErrorNumber]description]);
//  NSLog(@"keyErrorString:%@",[[event paramDescriptorForKeyword:keyErrorString]description]);
//  NSLog(@"keyProcessSerialNumber:%@",[[event paramDescriptorForKeyword:keyProcessSerialNumber]description]);
//  NSLog(@"keyPreDispatch:%@",[[event paramDescriptorForKeyword:keyPreDispatch]description]);
//  NSLog(@"keySelectProc:%@",[[event paramDescriptorForKeyword:keySelectProc]description]);
//  NSLog(@"keyAERecorderCount:%@",[[event paramDescriptorForKeyword:keyAERecorderCount]description]);
//  NSLog(@"keyAEVersion:%@",[[event paramDescriptorForKeyword:keyAEVersion]description]);
//}


- (void)handleOpenDocumentsEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
  NSAppleEventDescriptor* fileListDescriptor = [event paramDescriptorForKeyword:keyDirectObject];
  // Descriptor list indexing is one-based...
  NSInteger numberOfFiles = [fileListDescriptor numberOfItems];
  NSLog(@"filenumber:%ld",(long)numberOfFiles);
  if(numberOfFiles == 0){
    NSData *eventData = [event data];
    unsigned char *buffer = malloc(sizeof(UInt16));
    [eventData getBytes: buffer range:NSMakeRange(422, sizeof(UInt16))];
    UInt16 x = *(UInt16 *)buffer;
    if (x == ((UInt16)65534)) {
      x = 0;
    }
    // check to see if Unity didn't pass in a line
    if(x >= 17477) {
      x = 0;
    }
    
    NSString* filepath = [[event descriptorForKeyword:keyDirectObject] stringValue];
    filepath = [filepath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    filepath = [filepath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    [self openFile:filepath lineNum:x];
  }else{
    for (NSInteger i = 1; i <= numberOfFiles; i++) {
      NSString* filepath = [[fileListDescriptor descriptorAtIndex:i] stringValue];
      filepath = [filepath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      filepath = [filepath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
      NSLog(@"filepath:[%ld],%@",(long)i,filepath);
      [self openFile:filepath lineNum:0];
    }
  }
}

-(void)openFile:(NSString*)filepath lineNum:(UInt16) lineNum{
  NSLog(@"cmdPath: %@",cmdPath);
  NSLog(@"editor:%@,useTmux:%hhd",[settings editor],[settings useTmux]);
  NSLog(@"filepath: %@:%d",filepath,lineNum);
  NSPipe *pipe = [NSPipe pipe];
  NSFileHandle * file = pipe.fileHandleForReading;
  NSTask *task = [[NSTask alloc] init];
  task.launchPath = cmdPath;
  NSString * options = @"";
  if(lineNum > 0 ){
    options = [NSString stringWithFormat:@"+normal %dG1|",lineNum+1];
  }
  task.arguments = @[filepath,
                     options,
                     [settings editor],
                     [NSString stringWithFormat:@"%hhd",[settings useTmux]]
                     ];
  task.standardOutput = pipe;
  [task launch];
  NSData *data = [file readDataToEndOfFile];
  [file closeFile];
  NSString *cmdOutput=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSLog(@"openxvim result: \n%@",cmdOutput );
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
  NSLog(@"openFile: %@",filename);
  return TRUE;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}
-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
  //  NSLog(@"AAAAAAAABBBBBBB");
  return true;
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
  //  NSLog(@"###################");
  //can't get new arguments
  //  NSArray<NSString*> * args = [[NSProcessInfo processInfo] arguments];
  //  for(NSString *item in args){
  //    NSLog(@"%@",item);
  //  }
  return true;
}

@end
