//
//  CGRoom.h
//  ToBeDJ
//
//  Created by Yian Cheng on 8/7/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface CGRoom : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *masterDJName;
@property (nonatomic, copy) NSString *masterDJObjectId;
@property int listeners;
@property (nonatomic, strong) UIImage *currentSongImage;
@property (nonatomic, strong) PFObject *roomParseObject;

@end
