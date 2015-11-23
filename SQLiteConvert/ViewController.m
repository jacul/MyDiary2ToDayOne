//
//  ViewController.m
//  SQLiteConvert
//
//  Created by zxd on 15/11/21.
//
//

#import "ViewController.h"
#import <FMDB/FMDB.h>

#define kKEY_ENTRYDATE @"ZTIMESTAMP"
#define kKEY_ENTRYTEXT @"ZENTRYTEXT"


@interface ViewController()

@property (nonatomic, readwrite) NSDate *referenceDate;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (NSDate *)referenceDate
{
    if (!_referenceDate) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd HH-mm-ss z"];
        _referenceDate = [formatter dateFromString:@"2001-01-01 00:00:00 +0000"];
    }
    return _referenceDate;
}

- (IBAction)clickSelectFile:(id)sender {

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:@[@"sqlite"]];
    
    if ([openPanel runModal] == NSModalResponseOK) {
        
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        [savePanel setAllowedFileTypes:@[@"txt"]];
        [savePanel setNameFieldStringValue:@"MyDiary2"];
        
        if ([savePanel runModal] == NSModalResponseOK) {
            
            NSArray* urls = [openPanel URLs];
            [self asyncConvertDBFile:[urls firstObject] exportPath:[savePanel URL]];
        }
    }
}

- (void)asyncConvertDBFile:(NSURL *)dbURL exportPath:(NSURL *)saveURL
{
    dispatch_async(dispatch_queue_create("work", 0), ^{
        [self readDataAndWriteToFileWithDB:dbURL.path savePath:saveURL.path];
    });
}

- (void)readDataAndWriteToFileWithDB:(NSString *)dbPath savePath:(NSString *)savePath
{
    FMDatabase *database = [FMDatabase databaseWithPath:dbPath];
    
    if ([database open]) {
        FMResultSet *result = [database executeQuery:@"SELECT ZTIMESTAMP, ZENTRYTEXT FROM ZENTRY ORDER BY ZTIMESTAMP DESC"];
        
        NSOutputStream *output = [[NSOutputStream alloc] initToFileAtPath:savePath append:NO];
        [output open];
        
        NSDateFormatter *entryDateFormatter = [NSDateFormatter new];
        [entryDateFormatter setDateFormat:@"YYYY-MM-dd HH:mm"];
        
        while ([result next]) {
            double timestamp = [result doubleForColumn:kKEY_ENTRYDATE];
            if (timestamp < 0) {
                NSLog(@"Wrong date in entry: %@", [result stringForColumn:kKEY_ENTRYTEXT]);
                continue;
            }
            NSDate *entryDate = [NSDate dateWithTimeInterval:timestamp sinceDate:self.referenceDate];
            NSMutableString *entryFullText = [NSMutableString new];
            [entryFullText appendFormat:@"Date: %@\n\n", [entryDateFormatter stringFromDate:entryDate]];
            [entryFullText appendFormat:@"%@\n\n", [result stringForColumn:kKEY_ENTRYTEXT]];
            
            NSData *data = [entryFullText dataUsingEncoding:NSUTF8StringEncoding];
            [output write:(const uint8_t *)data.bytes maxLength:data.length];
        }
        [output close];
        [database close];
        
        [self showResult:@"File generated successfully"];
    } else {
        [self showResult:@"Database file can't be accessed"];
    }
}

- (void)showResult:(NSString *)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert addButtonWithTitle:@"OK"];
        
        [alert setMessageText:text];
        
        [alert setAlertStyle:NSInformationalAlertStyle];
        
        [alert runModal];
    });
}

@end
