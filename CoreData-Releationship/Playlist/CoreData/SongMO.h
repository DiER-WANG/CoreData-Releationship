//
//  SongMO.h
//  zapyaNewPro
//
//  Created by wangchangyang on 2016/11/14.
//  Copyright © 2016年 dongxin. All rights reserved.
//

#import <CoreData/CoreData.h>

@class PlaylistMO;
@interface SongMO : NSManagedObject

@property (nonatomic, copy)     NSString    *artist;
@property (nonatomic, copy)     NSString    *title;
@property (nonatomic, copy)     NSString    *type;
@property (nonatomic, copy)     NSString    *url;
@property (nonatomic, copy)     NSString    *songId;
@property (nonatomic, strong)   NSMutableSet<PlaylistMO *>     *playlists;


@end
