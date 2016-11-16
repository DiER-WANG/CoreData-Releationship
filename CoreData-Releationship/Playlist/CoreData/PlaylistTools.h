//
//  PlaylistTools.h
//  zapyaNewPro
//
//  Created by wangchangyang on 2016/11/11.
//  Copyright © 2016年 dongxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define WCY_ERROR(ErrorMsg) [NSError \
                         errorWithDomain:@"wangchangyang的数据库错误"\
                                    code:20000 \
                                userInfo:@{NSLocalizedDescriptionKey:\
                                                        (ErrorMsg) \
                            }]


@interface PlaylistTools : NSObject

@property (nonatomic, strong) NSManagedObjectContext *moc;

+ (instancetype)sharedInstance;

- (NSError *)saveContext;

#pragma mark - C
#pragma mark 创建歌单同时向歌单中添加歌曲/向已有歌单中添加歌曲
- (void)createPlaylist:(NSString *)playlistTitle songs:(NSArray *)songTitles withResult:(void(^)(NSArray *failureArr, NSError *error))completionHandler;

#pragma mark - U
#pragma mark 更新歌单的标题
- (void)updatePlaylistTitle:(NSString *)originTitle title:(NSString *)newTitle withResult:(void(^)(NSArray *failureArr, NSError *error))completionHandler;

#pragma mark - R
#pragma mark 获取所有的歌单或歌曲
- (void)retriveAllPlaylists:(NSUInteger)pageSize offset:(NSUInteger)currentPage withResult:(void(^)(NSArray *resultArr, NSError *error))completionHandler;
- (void)retriveAllSongs:(NSUInteger)pageSize offset:(NSUInteger)currentPage withResult:(void(^)(NSArray *resultArr, NSError *error))completionHandler;

#pragma mark 获取指定的歌单或歌曲
- (void)retriveOnePlaylist:(NSString *)playlistTitle withResult:(void(^)(NSArray *resultArr, NSError *error))complextionHandler;
- (void)retriveManyPlaylists:(NSArray *)playlistTitles withResult:(void (^)(NSArray *, NSError *))completionHandler;
- (void)retriveOneSong:(NSString *)songUrl withResult:(void(^)(NSArray *resultArr, NSError *error))completionHandler;
- (void)retriveManySongs:(NSArray *)songUrls withResult:(void (^)(NSArray *, NSError *))completionHandler;

#pragma mark - D
#pragma mark 从歌单中删除指定音乐文件
- (void)deleteSongs:(NSArray *)songUrls fromPlaylist:(NSString *)playlistTitle withReult:(void(^)(NSArray *failureArr, NSError *error))completionHandler;
#pragma mark 从数据库中删除指定音乐文件
- (void)deleteSongs:(NSArray *)songUrls withReult:(void (^)(NSArray *, NSError *))completionHandler;
#pragma mark 从数据库中删除指定歌单
- (void)deletePlaylists:(NSArray *)playlistTitles withReult:(void(^)(NSArray *failureArr, NSError *error))completionHandler;

@end
