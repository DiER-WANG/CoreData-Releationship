//
//  PlaylistTools.m
//  zapyaNewPro
//
//  Created by wangchangyang on 2016/11/11.
//  Copyright © 2016年 dongxin. All rights reserved.
//

#import "PlaylistTools.h"
#import <CoreData/CoreData.h>
#import "PlaylistMO.h"
#import "SongMO.h"

static PlaylistTools *singleton = nil;



@implementation PlaylistTools

#pragma mark - Core Data 初始化设置
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initializeCoreData];
    }
    return self;
}

- (void)initializeCoreData {
    
    // 找着 MOM
    NSURL *momURL = [[NSBundle mainBundle] URLForResource:@"Playlist" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    if (!mom) {
        NSLog(@"Error initializing Managed Object Model");
        return;
    }
    
    // 找着 PSC
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    // 找着 MOC
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    // 设置 PSC
    [moc setPersistentStoreCoordinator:psc];
    
    [self setMoc:moc];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"Playlist.sqlite"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error = nil;
        
        NSPersistentStoreCoordinator *psc = [[self moc] persistentStoreCoordinator];
        
        NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
        if (!store) {
            NSLog(@"Core Data Error: %@", error.localizedDescription);
        }
    });
};

- (NSError *)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self moc];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return error;
        } else {
            return nil;
        }
    }
    return nil;
}

#pragma mark - C
#pragma mark 创建歌单同时向歌单中添加歌曲/向已有歌单中添加歌曲
- (void)createPlaylist:(NSString *)playlistTitle songs:(NSArray *)songUrls withResult:(void(^)(NSArray *failureArr, NSError *error))completionHandler {
    
    NSManagedObjectContext *moc = [self moc];
    __weak typeof(self) weakSelf = self;
    // 像 Playlist 数据库中 搜索 是否有该歌单
    
    [self retriveOnePlaylist:playlistTitle withResult:^(NSArray *playlistResultArr, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            completionHandler(nil, error);
        } else {
            // 如果存在该歌单
            if (playlistResultArr.count > 0) {
                __block PlaylistMO *targetPlaylistMO = playlistResultArr.firstObject;
                
                // 如果歌曲数组不为空，则向该歌单中添加歌曲
                if (songUrls.count > 0) {
                    __block NSError *mmError = nil;
                    __block NSMutableArray *failure = [[NSMutableArray alloc] init];
                
                    for (NSDictionary *songDict in songUrls) {
                        // 判断该歌曲是否已存在数据库中
                        NSString *songUrl = [songDict objectForKey:@"url"];
                        
                        if (!songUrl) {
                            songUrl = [NSString stringWithFormat:@"wangchangyang/%@", @(arc4random_uniform(200))];
                        }
                        
                        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                        [strongSelf retriveOneSong:songUrl withResult:^(NSArray *songResultArr, NSError *error) {
                            
                            if (error) {
                                mmError = error;
                            } else {
                                // 如果存在，更新该歌曲的 playlists 属性
                                if (songResultArr.count > 0) {
                                    SongMO *targetSong = songResultArr.firstObject;
                                    // ? 同时更新两个 MO 还是只需要更新一个 MO
                                    // 修改关系这件事需要好好说明一下：我们只需要修改关系一方，Core Data 会自动替我们处理好剩下的事情
                                    
                                    __block BOOL alreadyHas = NO;
                                    [targetPlaylistMO.songs enumerateObjectsUsingBlock:^(SongMO * _Nonnull obj, BOOL * _Nonnull stop) {
                                        if ([obj.url isEqualToString:targetSong.url]) {
                                            alreadyHas = YES;
                                        }
                                    }];
                                    
                                    if (alreadyHas) {
                                        mmError = WCY_ERROR(@"该歌单中已包含该歌曲");
                                    } else {
                                        [targetSong.playlists addObject:targetPlaylistMO];
                                        [targetPlaylistMO.songs addObject:targetSong];
                                    }
                                } else {
                                    // 如果不存在，添加歌曲到数据库中
                                    SongMO *newSongMO = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:moc];
                                    NSString *title = [songDict objectForKey:@"title"];
                                    if (!title) {
                                        title = @"test";
                                    }
                                    NSString *url = [songDict objectForKey:@"url"];
                                    if (!url) {
                                        url = [NSString stringWithFormat:@"wangchangyang/%@", @(arc4random_uniform(200))];
                                    }
                                    NSString *type = [songDict objectForKey:@"type"];
                                    if (!type) {
                                        type = @"mp3";
                                    }
                                    NSString *songId = [songDict objectForKey:@"songId"];
                                    if (!songId) {
                                        songId = [NSString stringWithFormat:@"wangchangyang/%@", @(arc4random_uniform(200))];
                                    }
                                    newSongMO.title = title;
                                    newSongMO.url = url;
                                    newSongMO.type = type;
                                    newSongMO.songId = songId;
                                    [newSongMO.playlists addObject:targetPlaylistMO];
                                    [targetPlaylistMO.songs addObject:newSongMO];
                                }
                            }
                            dispatch_semaphore_signal(sema);
                        }];
                        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                        // 保存失败
                        if (([moc hasChanges] && ![moc save:&mmError]) || mmError) {
                            NSLog(@"Unresolved error %@, %@", mmError, [mmError userInfo]);
                            completionHandler(failure,
                                              mmError);
                            break;
                        } else {
                        // 保存成功
                            completionHandler(nil,
                                              nil);
                        }
                    }
                } else {
                    // 如果不存在歌曲
                    // 提醒用户歌单已存在
                    completionHandler(nil, WCY_ERROR(@"歌单名称已存在，请修改后重试"));
                }
                
            } else {
                // 如果不存在该歌单，在该数据库中创建该歌单
                PlaylistMO *newPlaylist = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:moc];
                
                newPlaylist.title = playlistTitle;
                newPlaylist.createDate = [NSDate date];
                newPlaylist.songs = [[NSMutableSet alloc] init];
                
                __block NSError *mmError = nil;
                __block NSMutableArray *failure = [[NSMutableArray alloc] init];
                
                for (NSDictionary *songDict in songUrls) {
                    // 判断该歌曲是否已存在数据库中
                    NSString *songUrl = [songDict objectForKey:@"url"];
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    [strongSelf retriveOneSong:songUrl withResult:^(NSArray *songResultArr, NSError *error) {
                        if (error) {
                            mmError = error;
                        } else {
                            // 如果存在，更新该歌曲的 playlists 属性
                            if (songResultArr.count > 0) {
                                SongMO *targetSong = songResultArr.firstObject;
                                // ? 同时更新两个 MO 还是只需要更新一个 MO
                                [targetSong.playlists addObject:newPlaylist];
                                // [newPlaylist.songs addObject:targetSong];
                            } else {
                                // 如果不存在，添加歌曲到数据库中
                                SongMO *newSongMO = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:moc];
                                NSString *title = [songDict objectForKey:@"title"];
                                if (!title) {
                                    title = @"test";
                                }
                                NSString *url = [songDict objectForKey:@"url"];
                                if (!url) {
                                    url = [NSString stringWithFormat:@"wangchangyang/%@", @(arc4random_uniform(200))];
                                }
                                NSString *type = [songDict objectForKey:@"type"];
                                if (!type) {
                                    type = @"mp3";
                                }
                                NSString *songId = [songDict objectForKey:@"songId"];
                                if (!songId) {
                                    songId = [NSString stringWithFormat:@"wangchangyang/%@", @(arc4random_uniform(200))];
                                }
                                newSongMO.title = title;
                                newSongMO.url = url;
                                newSongMO.type = type;
                                newSongMO.songId = songId;
                                // ?
                                [newSongMO.playlists addObject:newPlaylist];
                                [newPlaylist.songs addObject:newSongMO];
                            }
                        }
                        
                        dispatch_semaphore_signal(sema);
                    }];
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    if (mmError) {
                        break;
                    }
                }
                
                if (([moc hasChanges] && ![moc save:&mmError]) || mmError) {
                    NSLog(@"Unresolved error %@, %@", mmError, [mmError userInfo]);
                    completionHandler(failure,
                                      mmError);
                } else {
                    completionHandler(nil,
                                      nil);
                }
            }
        }
    }];
    
}

#pragma mark - U
#pragma mark 更新歌单的标题
- (void)updatePlaylistTitle:(NSString *)originTitle title:(NSString *)newTitle withResult:(void(^)(NSArray *failureArr, NSError *error))completionHandler {
    
    __block BOOL isAlreadyHas = NO;
    __block NSError *existError = nil;
    dispatch_semaphore_t ss = dispatch_semaphore_create(0);
    [self retriveOnePlaylist:newTitle withResult:^(NSArray *resultArr, NSError *error) {
        if (error) {
            existError = error;
        } else {
            if (resultArr.count > 0) {
                isAlreadyHas = YES;
                NSString *msg = [NSString stringWithFormat:@"%@ 歌单已存在", newTitle];
                existError = WCY_ERROR(msg);
            }
        }
        dispatch_semaphore_signal(ss);
    }];
    dispatch_semaphore_wait(ss, DISPATCH_TIME_FOREVER);
    
    if (isAlreadyHas || existError) {
        completionHandler(nil, existError);
        return;
    }
    
    __block NSError *merror = nil;
    [self retriveOnePlaylist:originTitle withResult:^(NSArray *resultArr, NSError *error) {
        if (error) {
            merror = error;
        } else {
            if (resultArr.count > 0) {
                PlaylistMO *list = resultArr.firstObject;
                list.title = newTitle;
                merror = [self saveContext];
            } else {
                merror = WCY_ERROR(@"数据库中不存在该歌单");
            }
        }
        
        completionHandler(nil, merror);
    }];
}
#pragma mark - R
#pragma mark 查询 指定的歌单 及其 歌单中的所有 歌曲
- (void)retriveOnePlaylist:(NSString *)playlistTitle withResult:(void (^)(NSArray *, NSError *))completionHandler {
    
    [self retriveManyPlaylists:@[playlistTitle] withResult:completionHandler];
}
- (void)retriveManyPlaylists:(NSArray *)playlistTitles withResult:(void (^)(NSArray *, NSError *))completionHandler {
    
    NSManagedObjectContext *moc = [self moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title IN %@", playlistTitles];
    request.predicate = predicate;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Playlist"
                                              inManagedObjectContext:moc];
    request.entity = entity;
    
    NSError *error = nil;
    NSArray *result = [[moc executeRequest:request error:&error] finalResult];
    
    completionHandler(result, error);
}
#pragma mark 查询指定的歌曲 及所有包含该歌曲的歌单
- (void)retriveOneSong:(NSString *)songUrl withResult:(void (^)(NSArray *, NSError *))completionHandler {
    
    [self retriveManySongs:@[songUrl] withResult:completionHandler];
}
- (void)retriveManySongs:(NSArray *)songUrls withResult:(void (^)(NSArray *, NSError *))completionHandler {
    
    NSManagedObjectContext *moc = [self moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url IN %@", songUrls];
    request.predicate = predicate;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song"
                                              inManagedObjectContext:moc];
    request.entity = entity;
    
    NSError *error = nil;
    NSArray *result = [[moc executeRequest:request error:&error] finalResult];
    
    completionHandler(result, error);
}
#pragma mark 查询 所有的歌单/歌曲 及 歌单／歌曲中所有的信息
- (void)retriveAllPlaylists:(NSUInteger)pageSize offset:(NSUInteger)currentPage withResult:(void (^)(NSArray *, NSError *))completionHandler {
    NSManagedObjectContext *moc = [self moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Playlist"
                                              inManagedObjectContext:moc];
    request.entity = entity;
    
    NSError *error = nil;
    NSArray *result = [[moc executeRequest:request error:&error] finalResult];
    
    completionHandler(result, error);
}
- (void)retriveAllSongs:(NSUInteger)pageSize offset:(NSUInteger)currentPage withResult:(void (^)(NSArray *, NSError *))completionHandler {
    NSManagedObjectContext *moc = [self moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song"
                                              inManagedObjectContext:moc];
    request.entity = entity;
    
    NSError *error = nil;
    NSArray *result = [[moc executeRequest:request error:&error] finalResult];
    
    completionHandler(result, error);
}

#pragma mark - D
#pragma mark 从指定歌单中删除指定歌曲
- (void)deleteSongs:(NSArray *)songUrls fromPlaylist:(NSString *)playlistTitle withReult:(void(^)(NSArray *failureArr, NSError *error))completionHandler {
    [self retriveOnePlaylist:playlistTitle withResult:^(NSArray *resultArr, NSError *error) {
        if (error) {
            completionHandler(nil, error);
        } else {
            if (resultArr.count > 0) {
                PlaylistMO *playlist = resultArr.firstObject;
                if (playlist.songs.count > 0) {
                    for (NSString *songUrl in songUrls) {
                        [playlist.songs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SongMO * _Nonnull obj, BOOL * _Nonnull stop) {
                            if ([obj.url isEqualToString:songUrl]) {
                                [playlist.songs removeObject:obj];
                                [obj.playlists removeObject:playlist];
                            }
                        }];
                    }
                    NSError *error = [self saveContext];
                    // 删除失败
                    if (error) {
                        completionHandler(nil, error);
                    } else {
                        // 删除成功
                        completionHandler(nil, nil);
                    }
                } else {
                    completionHandler(nil, WCY_ERROR(@"歌单中没有歌曲，请检查后重试。"));
                }
            } else {
                completionHandler(nil, WCY_ERROR(@"歌单名称不存在，请检查后重试。"));
            }
        }
    }];
}
#pragma mark 从数据库中删除指定音乐文件
- (void)deleteSongs:(NSArray *)songUrls withReult:(void (^)(NSArray *, NSError *))completionHandler {
    
    __block NSError *merror = nil;
    __block NSMutableArray *failure = [[NSMutableArray alloc] init];
    
    for (NSString *songUrl in songUrls) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self retriveOneSong:songUrl withResult:^(NSArray *resultArr, NSError *error) {
            
            if (error) {
                merror = error;
            } else {
                if (resultArr.count > 0) {
                    SongMO *song = resultArr.firstObject;
                    NSMutableSet *lists = song.playlists;
                    [lists enumerateObjectsUsingBlock:^(PlaylistMO *obj, BOOL * _Nonnull stop) {
                        [obj.songs removeObject:song];
                    }];
                    [song.playlists removeAllObjects];
                    [[self moc] deleteObject:song];
                } else {
                    NSString *errorMsg = [NSString stringWithFormat:@"数据库中不存在该歌曲：%@", songUrl];
                    merror = WCY_ERROR(errorMsg);
                    [failure addObject:songUrl];
                }
            }
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        if (merror) {
            break;
        }
    }
    
    if (merror) {
        completionHandler(nil, merror);
    } else {
        merror = [self saveContext];
        if (merror) {
            completionHandler(nil, merror);
        } else {
            completionHandler(nil, nil);
        }
    }
    /*
    __block NSError *merror = nil;
    [self retriveManyPlaylists:playlistTitles withResult:^(NSArray *playlistArr, NSError *error) {
        if (error) {
            merror = error;
        } else {
            [playlistArr enumerateObjectsUsingBlock:^(PlaylistMO *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj.songs enumerateObjectsUsingBlock:^(SongMO * _Nonnull objSong, BOOL * _Nonnull stop) {
                    [objSong.playlists removeObject:obj];
                }];
                [obj.songs removeAllObjects];
            }];
        }
    }];
    
    if (merror) {
        completionHandler(nil, merror);
    } else {
        merror = [self saveContext];
        if (merror) {
            completionHandler(nil, merror);
        } else {
            completionHandler(nil, nil);
        }
    }
     */
    
}
#pragma mark 从数据库中删除指定歌单 

/**
 从数据库中删除指定歌单

 @param playlistTitles 要删除的 歌单标题 数组
 @param completionHandler 结果
 */
- (void)deletePlaylists:(NSArray *)playlistTitles withReult:(void (^)(NSArray *, NSError *))completionHandler {
    __block NSError *merror = nil;
    __block NSMutableArray *failure = [[NSMutableArray alloc] init];
    for (NSString *playlistTitle in playlistTitles) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self retriveOnePlaylist:playlistTitle withResult:^(NSArray *resultArr, NSError *error) {
            if (error) {
                merror = WCY_ERROR(@"数据库发生错误");
            } else {
                if (resultArr.count > 0) {
                    PlaylistMO *list = resultArr.firstObject;
                    NSMutableSet *songs = list.songs;
                    [songs enumerateObjectsUsingBlock:^(SongMO *obj, BOOL * _Nonnull stop) {
                        [obj.playlists removeObject:list];
                    }];
                    [list.songs removeAllObjects];
                    [[self moc] deleteObject:list];
                } else {
                    merror = WCY_ERROR(@"数据库中没有该歌单");
                    [failure addObject:playlistTitle];
                }
            }
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        if (merror) {
            break;
        }
    }
    if (merror) {
        completionHandler(failure, merror);
    } else {
        NSError *error = [self saveContext];
        if (error) {
            completionHandler(nil, error);
        } else {
            completionHandler(nil, nil);
        }
    }
}


@end
