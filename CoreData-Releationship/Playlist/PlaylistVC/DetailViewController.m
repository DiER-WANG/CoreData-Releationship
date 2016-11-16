//
//  DetailViewController.m
//  zapyaNewPro
//
//  Created by wangchangyang on 2016/11/16.
//  Copyright © 2016年 dongxin. All rights reserved.
//

#import "DetailViewController.h"
#import "SongMO.h"
#import "PlaylistMO.h"


@interface DetailViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *dismiss = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, SCREEN_WIDTH, 44)];
    [dismiss setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:dismiss];
    [dismiss addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT - 64) style:UITableViewStylePlain];
        [self.view addSubview:_tableView];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
    DetailViewController *vc = [[DetailViewController alloc] init];
    id target = _datas[indexPath.row];
    NSArray *data = nil;
    if ([target isKindOfClass:[SongMO class]]) {
        SongMO *song = (SongMO *)target;
        data = [NSArray arrayWithArray:song.playlists.allObjects];
    } else {
        PlaylistMO *list = (PlaylistMO *)target;
        data = [NSArray arrayWithArray:list.songs.allObjects];
    }
    vc.datas = data;
    [self presentViewController:vc animated:YES completion:nil];
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
