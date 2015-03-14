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

#define SEC_Category 0
#define SEC_Subscription 1
#define SEC_Reset 2
#define SEC_Info 3

#define SECTION_COUNT 3

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
            
            if (data != nil) {
                _catagories = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            }
            
            _loading = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SEC_Category] withRowAnimation:UITableViewRowAnimationFade];
            });
        });
    }
    _hosts = [[NSUserDefaults standardUserDefaults] objectForKey:@"hosts"];
    if (_hosts != nil && token != nil) {
        NSMutableArray *array = [NSMutableArray array];
        [_hosts enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            [array addObject:[NSMutableDictionary dictionaryWithDictionary:obj]];
        }];
        _hosts = array;
        
        [self loadHostList];
    }
    
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 30.0)];
        l.text = @"알림 서비스가 비활성 상태입니다.";
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor grayColor];
        self.tableView.tableHeaderView = l;
    }
}

- (void)loadHostList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://push.smoon.kr/v1/hosts"]];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        
        if (data == nil) {
            return;
        }
        
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
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SEC_Subscription] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView reloadData];
            }
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_COUNT;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *titles = @[ @"카테고리", @"구독", @"", @"" ];
    return titles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SEC_Category: return _catagories != nil ? [_catagories[@"categories"] count] : 1;
        case SEC_Subscription: return MAX([_hosts count], 1);
        case SEC_Reset: return 1;
        case SEC_Info: return 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SEC_Category && _catagories == nil) {
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
    
    if (indexPath.section < SEC_Reset) {
        cell.accessoryView = [[UISwitch alloc] init];
        [(UISwitch *)cell.accessoryView addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
    }
    
    if (indexPath.section == SEC_Category) { //Categories
        cell.textLabel.text = _catagories[@"categories"][indexPath.row];
        [(UISwitch *)cell.accessoryView setOn:![_catagories[@"deny"] containsObject:_catagories[@"categories"][indexPath.row]]];
    } else if (indexPath.section == SEC_Subscription) { //hosts
        if (_hosts != nil) {
            cell.textLabel.text = _hosts[indexPath.row][@"title"];
            cell.detailTextLabel.text = _hosts[indexPath.row][@"webId"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [(UISwitch *)cell.accessoryView setOn:(indexPath.row > 0 ? [_hosts[indexPath.row][@"enabled"] boolValue] : [[NSUserDefaults standardUserDefaults] boolForKey:@"defaultHost"])];
        } else {
           
            if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
                [(UISwitch *)cell.accessoryView setEnabled:NO];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(loadHostList)];
                g.minimumPressDuration = 3.0;
                [cell addGestureRecognizer:g];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [(UISwitch *)cell.accessoryView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"defaultHost"]];
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == SEC_Reset) {
        [self resetData];
    }
}

- (void)onSwitch:(UISwitch *)sender {
    UITableViewCell *cell = (id)sender;
    while ([cell class] != [UITableViewCell class]) cell = (id)cell.superview;
    
    sender.enabled = NO;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (indexPath.section == SEC_Category) {
        UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [loading startAnimating];
        
        cell.accessoryView = loading;
        
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
                
                cell.accessoryView = sender;
            });
        });
    } else if (indexPath.section == SEC_Subscription) {
        UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [loading startAnimating];
        
        cell.accessoryView = loading;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *token = [(AppDelegate *)[[UIApplication sharedApplication] delegate] token];
            
            NSString *webId = _hosts == nil ? @"web.com.tistory.macnews" : _hosts[indexPath.row][@"webId"];
            webId = [NSString stringWithFormat:@"ios%@", [webId substringFromIndex:3]];
            
            NSMutableString *url = [NSMutableString stringWithFormat:@"https://push.smoon.kr/v1/devices/%@/registrations/%@", token, webId];
            if (sender.on == NO) [url appendString:@"/delete"];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            request.HTTPMethod = @"POST";
            request.HTTPBody = [[NSString stringWithFormat:@"version=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding];
            
            NSHTTPURLResponse *response = nil;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (response.statusCode != 200) sender.on = !sender.on;
                
                if (_hosts != nil && indexPath.row != 0) {
                    _hosts[indexPath.row][@"enabled"] = @(sender.on);
                    [[NSUserDefaults standardUserDefaults] setObject:_hosts forKey:@"hosts"];
                } else {
                    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"defaultHost"];
                }
                sender.enabled = YES;
                cell.accessoryView = sender;
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

    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"보관된 수신 데이터가 삭제됩니다.\n카테고리 및 구독 정보는 초기화 하지 않습니다."
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"데이터 초기화" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        //reset all
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"idx"];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] resetContext];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"데이터만 삭제 (이후 수신되는 알림만 받아집니다.)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        //reset data only
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] resetContext];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
