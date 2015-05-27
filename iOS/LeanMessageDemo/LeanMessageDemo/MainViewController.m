//
//  MainViewController.m
//  LeanMessageDemo
//
//  Created by lzw on 15/5/14.
//  Copyright (c) 2015年 leancloud. All rights reserved.
//

#import "MainViewController.h"
#import "ChatViewController.h"
#import "LoginViewController.h"
#import "AppDelegate.h"

#define kConversationId @"551a2847e4b04d688d73dc54"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UITextField *otherIdTextField;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;

@property (nonatomic, strong) AVIMClient *imClient;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择操作";
    self.imClient = ((AppDelegate *)[UIApplication sharedApplication].delegate).imClient;;
    
    self.welcomeLabel.text = [NSString stringWithFormat:@"%@  %@", self.welcomeLabel.text, self.imClient.clientId];
    //	self.otherIdTextField.text = @"b";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - actions

- (IBAction)onChatButtonClicked:(id)sender {
    NSString *otherId = self.otherIdTextField.text;
    if (otherId.length > 0) {
        [self createConversationsWithClientIds:@[otherId] completion:^(AVIMConversation *conversation, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            } else {
                [self performSegueWithIdentifier:@"toChat" sender:conversation];
            }
        }];
    }
}

- (IBAction)onStartGroupConversationButtonClicked:(id)sender {
    AVIMConversationQuery *query = [self.imClient conversationQuery];
    [query whereKey:@"objectId" equalTo:kConversationId];
    [query findConversationsWithCallback: ^(NSArray *conversations, NSError *error) {
        if (error) {
            NSLog(@"error = %@",error);
        } else {
            if (conversations.count == 0) {
                NSLog(@"聊天室不存在");
            } else {
                AVIMConversation *conversation = conversations[0];
                [conversation joinWithCallback:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        NSLog(@"error : %@",error);
                    } else {
                        [self performSegueWithIdentifier:@"toChat" sender:conversation];
                    }
                }];
            }
        }
    }];
}

- (IBAction)onLogoutButtonClicked:(id)sender {
    [self.imClient closeWithCallback: ^(BOOL succeeded, NSError *error) {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kLoginSelfIdKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ChatViewController *chatViewController = (ChatViewController *)segue.destinationViewController;
    chatViewController.conversation = sender;
}

#pragma mark - IM

- (void)createConversationsWithClientIds:(NSArray *)clientIds completion:(AVIMConversationResultBlock)completion{
    AVIMConversationQuery *query = [self.imClient conversationQuery];
    NSMutableArray *queryClientIDs = [[NSMutableArray alloc] initWithArray:clientIds];
    if ([queryClientIDs containsObject:self.imClient.clientId] == NO) {
        [queryClientIDs addObject:self.imClient.clientId];
    }
    [query whereKey:kAVIMKeyMember sizeEqualTo:queryClientIDs.count];
    [query whereKey:kAVIMKeyMember containsAllObjectsInArray:queryClientIDs];
    [query findConversationsWithCallback: ^(NSArray *objects, NSError *error) {
        if (error) {
            // 出错了，请稍候重试
            completion(nil, error);
        }
        else if (!objects || [objects count] < 1) {
            // 新建一个对话
            [self.imClient createConversationWithName:nil clientIds:queryClientIDs callback:completion];
        }
        else {
            // 已经有一个对话存在，继续在这一对话中聊天
            AVIMConversation *conversation = [objects lastObject];
            completion(conversation, nil);
        }
    }];
}


@end
