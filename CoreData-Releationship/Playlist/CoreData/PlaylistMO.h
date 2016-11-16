//
//  PlaylistMO.h
//  zapyaNewPro
//
//  Created by wangchangyang on 2016/11/14.
//  Copyright © 2016年 dongxin. All rights reserved.
//

#import <CoreData/CoreData.h>

@class SongMO;
@interface PlaylistMO : NSManagedObject

@property (nonatomic, strong)   NSDate      *createDate;
@property (nonatomic, copy)     NSString    *title;
@property (nonatomic, strong)   NSMutableSet<SongMO *>     *songs;

@end
