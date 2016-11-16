//
//  PlaylistViewController.m
//  zapyaNewPro
//
//  Created by wangchangyang on 2016/11/11.
//  Copyright © 2016年 dongxin. All rights reserved.
//

#import "PlaylistViewController.h"
#import "PlaylistTools.h"
#import "SongMO.h"
#import "PlaylistMO.h"

#import "DetailViewController.h"

@interface PlaylistViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) PlaylistTools *playtools;

@property (nonatomic, strong) NSArray *datas;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation PlaylistViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    if (!_playtools) {
        _playtools = [PlaylistTools sharedInstance];
    }
    
    self.view.backgroundColor = [UIColor blueColor];
    
    
    
    // Create = 创建 Update = 更新 Retrieve = 读取 Delete = 删除
    NSArray *titles = @[@"创建歌单／向歌单中添加歌曲", @"更新歌单标题", @"根据 歌单标题／歌曲路径 查找 歌单／歌曲", @"从数据库中删除歌单／从歌单中删除指定歌曲／从数据库中删除歌曲"];
    // 歌单的 增删改查
    for (NSUInteger i = 0; i < 4; i++) {
        CGFloat x = i * SCREEN_WIDTH * 0.25;
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x,
                                                                   20,
                                                                   SCREEN_WIDTH * 0.25,
                                                                   44)];
        [self.view addSubview:btn];
        btn.tag = 10 + i;
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn setBackgroundColor:RGB(arc4random_uniform(256),
                                    arc4random_uniform(256),
                                    arc4random_uniform(256),
                                    arc4random_uniform(256))];
        [btn addTarget:self
                action:@selector(curdMethod:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    UITableView *tableView  = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT - 64 - 44)];
    [self.view addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    _tableView = tableView;
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.view addSubview:btn];
    [btn setBackgroundColor:[UIColor redColor]];
    [btn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    btn.center = self.view.center;
    
    NSArray *aa = @[@"全部歌单", @"全部歌曲"];
    for (NSUInteger i = 0; i < 2; i++) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i * SCREEN_WIDTH * 0.5, SCREEN_HEIGHT - 44, SCREEN_WIDTH * 0.5, 44)];
        [self.view addSubview:btn];
        [btn setBackgroundColor:i == 0 ? [UIColor greenColor] : [UIColor redColor]];
        [btn addTarget:self action:(i == 0 ? @selector(reloadPlaylistsData) : @selector(reloadSongsData) ) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitle:aa[i] forState:UIControlStateNormal];
    }
    
    [self reloadPlaylistsData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    id target = _datas[indexPath.row];
    NSString *msg = @"";
    if ([target isKindOfClass:[SongMO class]]) {
        SongMO *song = (SongMO *)target;
        msg = song.url;
    } else {
        PlaylistMO *list = (PlaylistMO *)target;
        msg = list.title;
    }
    cell.textLabel.text = msg;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DetailViewController *detailVC = [[DetailViewController alloc] init];
    id target = _datas[indexPath.row];
    NSArray *data = nil;
    if ([target isKindOfClass:[SongMO class]]) {
        SongMO *song = (SongMO *)target;
        data = [NSArray arrayWithArray:song.playlists.allObjects];
    } else {
        PlaylistMO *list = (PlaylistMO *)target;
        data = [NSArray arrayWithArray:list.songs.allObjects];
    }
    detailVC.datas = data;
    
    [self presentViewController:detailVC animated:YES completion:nil];
}


- (void)curdMethod:(UIButton *)btn {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[btn titleForState:UIControlStateNormal] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    if (btn.tag == 10) {
    //"创建歌单／向歌单中添加歌曲"
        // 歌单 标题
        [alert addTextFieldWithConfigurationHandler:nil];
        alert.textFields.firstObject.placeholder = @"歌单标题";
        // 歌曲 路径
        [alert addTextFieldWithConfigurationHandler:nil];
        alert.textFields.lastObject.placeholder = @"歌曲路径";
        
        __weak typeof(_playtools) weak_playtools = _playtools;
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(weak_playtools) strong_playtools = weak_playtools;
        
            NSArray *songs = nil;
            if (alert.textFields.lastObject.text.length > 0) {
                songs = @[@{@"url":alert.textFields.lastObject.text}];
            }
            [strong_playtools createPlaylist:alert.textFields.firstObject.text
                                       songs:songs
                                  withResult:^(NSArray *failureArr, NSError *error) {
                NSString *msg = @"SUCCESS";
                if (error) {
                    msg = error.localizedDescription;
                }
                //[[ZapyaTools shareTool] makeAlterWithTitle:msg andIsShake:NO];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf reloadPlaylistsData];
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    } else if (btn.tag == 11) {
    // 更新歌单标题
        [alert addTextFieldWithConfigurationHandler:nil];
        alert.textFields.firstObject.placeholder = @"旧歌单标题";
        // 歌曲 路径
        [alert addTextFieldWithConfigurationHandler:nil];
        alert.textFields.lastObject.placeholder = @"新歌单标题";
        
        __weak typeof(_playtools) weak_playtools = _playtools;
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(weak_playtools) strong_playtools = weak_playtools;
            [strong_playtools updatePlaylistTitle:alert.textFields.firstObject.text title:alert.textFields.lastObject.text withResult:^(NSArray *failureArr, NSError *error) {
                NSString *msg = @"SUCCESS";
                if (error) {
                    msg = error.localizedDescription;
                }
               // [[ZapyaTools shareTool] makeAlterWithTitle:msg andIsShake:NO];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf reloadPlaylistsData];
            }];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    } else if (btn.tag == 12) {
     //@"查找歌单／查找歌曲"
        [alert addTextFieldWithConfigurationHandler:nil];
        alert.textFields.firstObject.placeholder = @"根据 歌单标题／歌曲路径 查找 歌单／歌曲";
        
        __weak typeof(_playtools) weak_playtools = _playtools;
        [alert addAction:[UIAlertAction actionWithTitle:@"查找歌曲" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(weak_playtools) strong_playtools = weak_playtools;
            [strong_playtools retriveOneSong:alert.textFields.firstObject.text
                                  withResult:^(NSArray *failureArr, NSError *error) {
                NSString *msg = @"SUCCESS";
                if (error) {
                    msg = error.localizedDescription;
                }
                //[[ZapyaTools shareTool] makeAlterWithTitle:msg andIsShake:NO];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf reloadSongsData];
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"查找歌单" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(weak_playtools) strong_playtools = weak_playtools;
            [strong_playtools retriveOnePlaylist:alert.textFields.firstObject.text withResult:^(NSArray *failureArr, NSError *error) {
                NSString *msg = @"SUCCESS";
                if (error) {
                    msg = error.localizedDescription;
                }
                //[[ZapyaTools shareTool] makeAlterWithTitle:msg andIsShake:NO];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf reloadPlaylistsData];
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
    } else {
        
        [alert addTextFieldWithConfigurationHandler:nil];
        alert.textFields.firstObject.placeholder = @"歌单标题";
        [alert addTextFieldWithConfigurationHandler:nil];
        alert.textFields.lastObject.placeholder = @"歌曲路径";
        
        __weak typeof(_playtools) weak_playtools = _playtools;
        [alert addAction:[UIAlertAction actionWithTitle:@"从数据库中删除歌单" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(weak_playtools) strong_playtools = weak_playtools;
            [strong_playtools deletePlaylists:@[alert.textFields.firstObject.text] withReult:^(NSArray *failureArr, NSError *error) {
                NSString *msg = @"SUCCESS";
                if (error) {
                    msg = error.localizedDescription;
                }
                //[[ZapyaTools shareTool] makeAlterWithTitle:msg andIsShake:NO];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf reloadPlaylistsData];
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"从数据库中删除歌曲" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(weak_playtools) strong_playtools = weak_playtools;
            [strong_playtools deleteSongs:@[@{@"url": alert.textFields.lastObject.text}] withReult:^(NSArray *failureArr, NSError *error) {
                NSString *msg = @"SUCCESS";
                if (error) {
                    msg = error.localizedDescription;
                }
                //[[ZapyaTools shareTool] makeAlterWithTitle:msg andIsShake:NO];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf reloadPlaylistsData];
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"从指定歌单中删除指定歌曲" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(weak_playtools) strong_playtools = weak_playtools;
            [strong_playtools deleteSongs:@[alert.textFields.lastObject.text] fromPlaylist:alert.textFields.firstObject.text withReult:^(NSArray *failureArr, NSError *error) {
                NSString *msg = @"SUCCESS";
                if (error) {
                    msg = error.localizedDescription;
                }
                //[[ZapyaTools shareTool] makeAlterWithTitle:msg andIsShake:NO];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf reloadPlaylistsData];
            }];
            
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadPlaylistsData {
 
    [_playtools retriveAllPlaylists:0 offset:0 withResult:^(NSArray *resultArr, NSError *error) {
        _datas = resultArr;
        [_tableView reloadData];
    }];
}

- (void)reloadSongsData {
    [_playtools retriveAllSongs:0 offset:0 withResult:^(NSArray *resultArr, NSError *error) {
        _datas = resultArr;
        [_tableView reloadData];
    }];
}


- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
