//
//  SettingViewController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 8..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "SettingViewController.h"
#import "NSString+URL.h"
#import "DetailViewController.h"
#import <MacnewsCore/MacnewsCore.h>
#import "AppDelegate.h"

#define SEC_Category 0
#define SEC_Subscription 1
#define SEC_Button 2
#define SEC_Remind 3
#define SEC_Reset 4

#define SECTION_COUNT 5

@implementation SettingViewController {
    NSDictionary *_catagories;
    BOOL _loading;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    if (_catagories == nil && [DataStore sharedData].token != nil) {
        [self loadCatagoryList];
    }
    
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 30.0)];
        l.text = @"알림 서비스가 비활성 상태입니다.";
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor grayColor];
        self.tableView.tableHeaderView = l;
    }
}

- (void)loadCatagoryList {
    _loading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *url = [NSString stringWithFormat:@"https://push.smoon.kr/setting/ios.com.tistory.macnews/%@", [DataStore sharedData].token];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        
        if (data != nil) {
            _catagories = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        }
        
        
        [[DataStore sharedData] updateHostSettings];
        
        _loading = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(SEC_Category, 2)] withRowAnimation:UITableViewRowAnimationFade];
        });
    });
}
- (void)enableMultiHosts {
    if ([DataStore sharedData].multiHostEnabled) return;
    
    [DataStore sharedData].multiHostEnabled = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSInteger count = [[DataStore sharedData] numberOfHosts];
        [[DataStore sharedData] updateHostSettings];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (count == [[DataStore sharedData] numberOfHosts]) {
                [self.tableView reloadData];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SEC_Subscription] withRowAnimation:UITableViewRowAnimationFade];
            }
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_COUNT;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *titles = @[ @"카테고리", @"구독", @"알림센터 버튼", @"나중에 알림", @"초기화" ];
    return titles[section];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SEC_Category: return _catagories != nil ? [_catagories[@"categories"] count] : 1;
        case SEC_Subscription: return [[DataStore sharedData] numberOfHosts];
        case SEC_Button: return 3;
        case SEC_Remind: return [[[DataStore sharedData] remindOptionTitles] count];
        case SEC_Reset: return 1;
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SEC_Button) {
        return 60.0;
    }
    return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SEC_Category && _catagories == nil) {
        UITableViewCell *infoCell = [tableView dequeueReusableCellWithIdentifier:_loading ? @"loading" : ([DataStore sharedData].token != nil ? @"error" : @"needToken") forIndexPath:indexPath];
        
        if (_loading == NO && [DataStore sharedData].token == nil) {
            UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
            infoCell.accessoryView = infoBtn;
            [infoBtn addTarget:self action:@selector(onNeedTokenInfo) forControlEvents:UIControlEventTouchUpInside];
        }
        
        return infoCell;
    }
    
    NSArray *types = @[ @"category", @"webId", @"button", @"remind", @"reset" ];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:types[indexPath.section] forIndexPath:indexPath];
    cell.accessoryView = nil;
    [cell.gestureRecognizers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [cell removeGestureRecognizer:obj];
    }];
    
    switch (indexPath.section) {
        case SEC_Category: {
            cell.accessoryView = [[UISwitch alloc] init];
            [(UISwitch *)cell.accessoryView addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = _catagories[@"categories"][indexPath.row];
            [(UISwitch *)cell.accessoryView setOn:![_catagories[@"deny"] containsObject:_catagories[@"categories"][indexPath.row]]];
            break;
        }
        case SEC_Subscription: {
            cell.accessoryView = [[UISwitch alloc] init];
            [(UISwitch *)cell.accessoryView addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
            NSDictionary *item = [[DataStore sharedData] hostAtIndex:indexPath.row];
            
            cell.textLabel.text = item[@"title"];
            cell.detailTextLabel.text = item[@"webId"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [(UISwitch *)cell.accessoryView setOn:[item[@"enabled"] boolValue]];
            
            if ([DataStore sharedData].multiHostEnabled == NO) {
                UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(enableMultiHosts)];
                g.minimumPressDuration = 3.0;
                [cell addGestureRecognizer:g];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
            break;
        }
        case SEC_Button: {
            cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"setting_button_option_%li", (long)indexPath.row]];
            cell.accessoryType = [DataStore sharedData].responsiveMode == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.accessoryView = [DataStore sharedData].responsiveMode == indexPath.row ? nil : [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, cell.contentView.frame.size.height)];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
        }
        case SEC_Remind: {
            cell.textLabel.text = [[DataStore sharedData] remindOptionTitles][indexPath.row];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = [DataStore sharedData].remindOption == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            
            break;
        }
        case SEC_Reset: {
            
            break;
        }
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == SEC_Reset) {
        [self resetData];
    } else if (indexPath.section == SEC_Button) {
        [DataStore sharedData].responsiveMode = indexPath.row;
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] registerDevice];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:SEC_Button] withRowAnimation:UITableViewRowAnimationNone];
    } else  if (indexPath.section == SEC_Remind) {
        [DataStore sharedData].remindOption = indexPath.row;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:SEC_Remind] withRowAnimation:UITableViewRowAnimationNone];
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
            NSMutableString *url = [NSMutableString stringWithFormat:@"https://push.smoon.kr/setting/ios.com.tistory.macnews/%@", [DataStore sharedData].token];
            
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
        BOOL on = sender.on;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            BOOL success = [[DataStore sharedData] setHost:[[DataStore sharedData] hostAtIndex:indexPath.row][@"webId"] enabled:on];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) sender.on = !sender.on;
                
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
        [[DataStore sharedData] resetIdx];
        [[DataStore sharedData] resetContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"데이터만 삭제 (이후 수신되는 알림만 받아집니다.)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        //reset data only
        [[DataStore sharedData] resetContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel handler:nil]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:alertController];
        [popup presentPopoverFromRect:self.view.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
    
    if ([@[ @"notification" ] containsObject:segue.identifier]) {
        [controller setDetailItem:nil];
        NSDictionary *item = sender;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:[[DataStore sharedData] hostWithWebId:item[@"webId"]][@"url"], item[@"arg"]]];
        
        [controller setUrl:url];
    }
    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    controller.navigationItem.leftItemsSupplementBackButton = YES;
}



@end
