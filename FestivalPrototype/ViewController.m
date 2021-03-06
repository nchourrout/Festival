//
//  ViewController.m
//  FestivalPrototype
//
//  Created by Nicolas Chourrout on 11/12/2013.
//  Copyright (c) 2013 Nicolas Chourrout. All rights reserved.
//

#import "ViewController.h"
#import "AEAudioController.h"
#import "AEAudioFilePlayer.h"
#import "User.h"


@interface ViewController ()

//Audio Engine
@property (nonatomic, strong) AEAudioController *audioController;
@property (nonatomic, strong) NSMutableArray *filePlayers;

// Users
@property(nonatomic, strong) NSMutableArray *users;
@property(nonatomic, strong) User *mainUser;

// Outlets
@property (strong, nonatomic) IBOutlet UIView *scene;

@property (strong, nonatomic) IBOutlet UITextField *xTextField;
@property (strong, nonatomic) IBOutlet UITextField *yTextField;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createUsers];
    
    [self updateUI];
    
    [self configurePlayer];
    
    [self play];
}

#pragma mark - Users
- (void)createUsers
{
    // Current User
    self.mainUser = [[User alloc] initWithName:@"Nico"
                                      playlist:nil
                                      position:CGPointMake(250.0f, 250.0f)];
    
    // Other users
    self.users = [@[] mutableCopy];
    
    User *sven = [[User alloc] initWithName:@"Sven"
                                   playlist:@[@"1"]
                                   position:CGPointMake(100.0f, 400.0f)];
    
    [self.users addObject:sven];
    User *luke = [[User alloc] initWithName:@"Luke"
                                   playlist:@[@"2"]
                                   position:CGPointMake(100.0f, 100.0f)];
    [self.users addObject:luke];
    
    User *maciej = [[User alloc] initWithName:@"Maciej"
                                   playlist:@[@"3"]
                                   position:CGPointMake(400.0f, 400.0f)];
    [self.users addObject:maciej];
    
    User *michal = [[User alloc] initWithName:@"Michal"
                                   playlist:@[@"4"]
                                   position:CGPointMake(400.0f, 100.0f)];
    [self.users addObject:michal];
    
    User *dustin = [[User alloc] initWithName:@"Dustin"
                                     playlist:@[@"4"]
                                     position:CGPointMake(500.0f, 500.0f)];
    [self.users addObject:dustin];
}

#pragma mark - Drawing

//Quick and dirty

- (void)updateUI
{
    // Textfields
    self.xTextField.text = [NSString stringWithFormat:@"%d", (NSInteger)self.mainUser.position.x];
    self.yTextField.text = [NSString stringWithFormat:@"%d", (NSInteger)self.mainUser.position.y];
    
    // Clean-up
    [[self.scene subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // Border
    self.scene.layer.borderColor = [[UIColor redColor] CGColor];
    self.scene.layer.borderWidth = 3.0f;
    
    // Users
    CGFloat userSize = 80.0f;
    for (User *user in self.users) {
        UIView *userView = [[UIView alloc] initWithFrame:CGRectMake(user.position.x - userSize/2,
                                                                   user.position.y - userSize/2,
                                                                   userSize,
                                                                   userSize)];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:userView.bounds];
        nameLabel.textColor = [UIColor blackColor];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.text = user.name;
        
        [userView addSubview:nameLabel];
        userView.backgroundColor = [self randomColor];
        
        [self.scene addSubview:userView];
    }
    
    { // Draw Main User
        UIView *mainUserView = [[UIView alloc] initWithFrame:CGRectMake(self.mainUser.position.x - userSize/2,
                                                                        self.mainUser.position.y - userSize/2,
                                                                        userSize,
                                                                        userSize)];
        mainUserView.alpha = 0.5;
        mainUserView.layer.cornerRadius = 50;
        mainUserView.backgroundColor = [UIColor blueColor];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:mainUserView.bounds];
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.text = [self.mainUser.name uppercaseString];
        
        [mainUserView addSubview:nameLabel];
        [self.scene addSubview:mainUserView];
    }
}

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

#pragma mark - Audio Player

- (void)configurePlayer
{
    self.audioController = [[AEAudioController alloc]
                           initWithAudioDescription:[AEAudioController interleaved16BitStereoAudioDescription]
                           inputEnabled:NO];
    
    self.audioController.preferredBufferDuration = 0.093;
    self.audioController.allowMixingWithOtherApps = NO;
    self.filePlayers = [NSMutableArray new];
    
    for (User *user in self.users) {
        
        NSURL *fileURL = user.currentTrack;
        
        // TODO: give each user its AEAudioFilePlayer
        AEAudioFilePlayer *filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:fileURL
                                                                 audioController:_audioController
                                                                           error:NULL];
        filePlayer.volume = [self volumeForUser:user];
        filePlayer.pan = [self panForUser:user];
        filePlayer.currentTime = 0; // set it to the time already elapsed on the user's track
                                    // for real time listening
        
        [self.filePlayers addObject:filePlayer];
    }
    [self.audioController addChannels:self.filePlayers];
}

- (void)play
{
    [self.audioController start:nil];
}

- (void)adjustChannels
{
    for (NSUInteger index = 0; index < [self.users count]; index++) {
        AEAudioFilePlayer *player = self.filePlayers[index];
        User *user = self.users[index];
        player.volume = [self volumeForUser:user];
        player.pan = [self panForUser:user];
    }
}

- (CGFloat)volumeForUser:(User *)user
{
    // TODO: compute the volume properly (http://sengpielaudio.com/calculator-distance.htm)
    CGFloat volume = ( self.scene.frame.size.width/2 - [self.mainUser distanceFrom:user] ) / self.scene.frame.size.width;
    volume = volume < 0 ? 0 : volume;
    NSLog (@"Volume for %@ is %f", user.name, volume);
    return volume;
}

- (CGFloat)panForUser:(User *)user
{
    // TODO: to implement
    return 0.0; // Range: -1.0 (left) to 1.0 (right)
}

#pragma mark - Moving around
- (IBAction)moveButtonPressed:(id)sender
{
    CGFloat x = [self.xTextField.text floatValue];
    CGFloat y = [self.yTextField.text floatValue];
    
    [self moveUserToPosition:CGPointMake(x, y)];
}

- (void)moveUserToPosition:(CGPoint)position
{
    self.mainUser.position = position;
    
    [self updateUI];
    
    [self adjustChannels];
}


@end
