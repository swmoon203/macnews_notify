//
//  SettingViewController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 8..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "SettingViewController.h"
#import "AppDelegate.h"
#import "NSString+URL.h"

@implementation SettingViewController {
    NSDictionary *_catagories;
    BOOL _loading;
    NSMutableArray *_hosts;
    NSArray *_hostList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *token = [(AppDelegate *)[[UIApplication sharedApplication] delegate] token];
    
    if (_catagories == nil && token != nil) {
        _loading = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *url = [NSString stringWithFormat:@"https://push.smoon.kr/setting/ios.com.tistory.macnews/%@", token];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            
            _catagories = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            
            _loading = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            });
        });
    }
    _hosts = [[NSUserDefaults standardUserDefaults] objectForKey:@"hosts"];
    if (_hosts != nil && token != nil) {
        _hosts = [NSMutableArray arrayWithArray:_hosts];
        [self loadHostList];
    }
}

- (void)loadHostList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://push.smoon.kr/v1/hosts"]];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        
        _hostList = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        NSMutableSet *enabledWebIds = [NSMutableSet setWithObject:@"web.com.tistory.macnews"];
        [_hosts enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            if ([obj[@"enabled"] boolValue]) [enabledWebIds addObject:obj[@"webId"]];
        }];
        
        NSMutableArray *newHosts = [NSMutableArray array];
        [_hostList enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            if ([obj[@"webId"] isEqualToString:@"web.com.tistory.macnews"]) {
                [newHosts addObject:obj];
                *stop = YES;
            }
        }];
        
        [_hostList enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            if ([obj[@"webId"] isEqualToString:@"web.com.tistory.macnews"] == NO) {
                NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:obj];
                [newHosts addObject:item];
                item[@"enabled"] = @([enabledWebIds containsObject:obj[@"webId"]]);
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL changed = [_hosts count] != [newHosts count];
            _hosts = newHosts;
            [[NSUserDefaults standardUserDefaults] setObject:_hosts forKey:@"hosts"];
            
            if (changed) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView reloadData];
            }
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *titles = @[ @"카테고리", @"구독", @"" ];
    return titles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return _catagories != nil ? [_catagories[@"categories"] count] : 1;
        }
        case 1: {
            return MAX([_hosts count], 1);
        }
        case 2: {
            return 1;
        }
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _catagories == nil) {
        NSString *token = [(AppDelegate *)[[UIApplication sharedApplication] delegate] token];
        UITableViewCell *infoCell = [tableView dequeueReusableCellWithIdentifier:_loading ? @"loading" : (token != nil ? @"error" : @"needToken") forIndexPath:indexPath];
        
        if (_loading == NO && token == nil) {
            UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
            infoCell.accessoryView = infoBtn;
            [infoBtn addTarget:self action:@selector(onNeedTokenInfo) forControlEvents:UIControlEventTouchUpInside];
        }
        
        return infoCell;
    }
    
    NSArray *types = @[ @"category", @"webId", @"reset" ];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:types[indexPath.section] forIndexPath:indexPath];
    cell.accessoryView = nil;
    [cell.gestureRecognizers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [cell removeGestureRecognizer:obj];
    }];
    
    if (indexPath.section == 0 || (indexPath.section == 1 && indexPath.row > 0)) {
        cell.accessoryView = [[UISwitch alloc] init];
        [(UISwitch *)cell.accessoryView addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
    }
    
    if (indexPath.section == 0) { //Categories
        cell.textLabel.text = _catagories[@"categories"][indexPath.row];
        [(UISwitch *)cell.accessoryView setOn:![_catagories[@"deny"] containsObject:_catagories[@"categories"][indexPath.row]]];
    } else if (indexPath.section == 1) { //hosts
        if (_hosts != nil) {
            cell.textLabel.text = _hosts[indexPath.row][@"title"];
            cell.detailTextLabel.text = _hosts[indexPath.row][@"webId"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [(UISwitch *)cell.accessoryView setOn:[_hosts[indexPath.row][@"enabled"] boolValue]];
        } else {
            UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(loadHostList)];
            g.minimumPressDuration = 3.0;
            [cell addGestureRecognizer:g];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2) {
        [self resetData];
    }
}

- (void)onSwitch:(UISwitch *)sender {
    UITableViewCell *cell = (id)sender;
    while ([cell class] != [UITableViewCell class]) cell = (id)cell.superview;
    
    sender.enabled = NO;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (indexPath.section == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *token = [(AppDelegate *)[[UIApplication sharedApplication] delegate] token];
            NSMutableString *url = [NSMutableString stringWithFormat:@"https://push.smoon.kr/setting/ios.com.tistory.macnews/%@", token];
            
            if (sender.on) [url appendString:@"/delete"];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            request.HTTPMethod = @"POST";
            request.HTTPBody = [[NSString stringWithFormat:@"keyword=%@", [_catagories[@"categories"][indexPath.row] stringByURLEncoded]] dataUsingEncoding:NSUTF8StringEncoding];
            
            NSHTTPURLResponse *response = nil;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
            
            NSLog(@"%@", response);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (response.statusCode != 200) sender.on = !sender.on;
                sender.enabled = YES;
            });
        });
    } else if (indexPath.section == 1) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *token = [(AppDelegate *)[[UIApplication sharedApplication] delegate] token];
            
            NSString *webId = _hosts[indexPath.row][@"webId"];
            webId = [NSString stringWithFormat:@"ios%@", [webId substringFromIndex:3]];
            
            NSMutableString *url = [NSMutableString stringWithFormat:@"https://push.smoon.kr/v1/devices/%@/registrations/%@", token, webId];
            if (sender.on == NO) [url appendString:@"/delete"];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            request.HTTPMethod = @"POST";
            
            NSHTTPURLResponse *response = nil;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (response.statusCode != 200) sender.on = !sender.on;
                
                _hosts[indexPath.row][@"enabled"] = @(sender.on);
                [[NSUserDefaults standardUserDefaults] setObject:_hosts forKey:@"hosts"];
                sender.enabled = YES;
            });
        });
    }
}

- (void)onNeedTokenInfo {
    [[[UIAlertView alloc] initWithTitle:@"안내"
                               message:@"카테고리 기능을 사용하려면 알림 서비스 권한이 필요합니다.\n알림을 원치 않을 경우 최초 한번의 활성화 후 차단하면 됩니다."
                              delegate:nil
                     cancelButtonTitle:@"확인"
                      otherButtonTitles:nil] show];
}

- (void)resetData {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"보관된 수신 데이터가 삭제됩니다.\n카테고리 및 구독 정보는 초기화 하지 않습니다."
                                                       delegate:self
                                              cancelButtonTitle:@"취소"
                                         destructiveButtonTitle:@"데이터 초기화"
                                              otherButtonTitles:@"데이터만 삭제 (이후 수신되는 알림만 받아집니다.)",
                            nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex) return;
    
    if (actionSheet.destructiveButtonIndex == buttonIndex) {
        //reset all
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"idx"];
    } else {
        //reset data only
    }
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] deleteAllObjects:@"Notification"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
}


@end
