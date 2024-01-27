//
//  BGControllerMusicFingerprint.m
//  Blog
//
//  Created by James Ajhar on 1/4/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGControllerMusicFingerprint.h"

NSString *kBGControllerMusicFingerprint = @"BGControllerMusicFingerprint";

@interface BGControllerMusicFingerprint ()

@property (strong, nonatomic) ENAPIRequest *request;
@property (readonly) NSString *apiKey;
@property (readonly) NSString *consumerKey;
@property (readonly) NSString *sharedSecret;

@end

@implementation BGControllerMusicFingerprint

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
}

@end
