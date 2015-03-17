#import "ARCreateAccountViewController.h"
#import "AROnboardingViewController.h"
#import "AROnboardingNavBarView.h"
#import "ARTextFieldWithPlaceholder.h"
#import "ARSecureTextFieldWithPlaceholder.h"
#import "ARUserManager.h"
#import "ARSpinner.h"
#import <ARAnalytics/ARAnalytics.h>
#import "ARAnalyticsConstants.h"
#import "UIView+HitTestExpansion.h"

//sigh
#define EMAIL_TAG 111
#define SOCIAL_TAG 222

@interface ARCreateAccountViewController ()<UITextFieldDelegate, UIAlertViewDelegate>
@property (nonatomic) AROnboardingNavBarView *navbar;
@property (nonatomic) ARTextFieldWithPlaceholder *name, *email, *password;
@property (nonatomic) ARSpinner *loadingSpinner;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSLayoutConstraint *keyboardConstraint;

@end

@implementation ARCreateAccountViewController

- (void)viewDidLoad
{
    self.navbar = [[AROnboardingNavBarView alloc] init];

    [self.view addSubview:self.navbar];
    [self.navbar.title setText:@"Create Account"];
    [self.navbar.back addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];

    [self.navbar.forward setTitle:@"JOIN" forState:UIControlStateNormal];
    [self.navbar.forward addTarget:self action:@selector(submit:) forControlEvents:UIControlEventTouchUpInside];

    UITapGestureRecognizer *keyboardCancelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:keyboardCancelTap];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    self.name = [[ARTextFieldWithPlaceholder alloc] init];
    self.name.placeholder = @"Full Name";
    self.name.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.name.autocorrectionType = UITextAutocorrectionTypeNo;
    self.name.returnKeyType = UIReturnKeyNext;
    self.name.keyboardAppearance = UIKeyboardAppearanceDark;

    self.email = [[ARTextFieldWithPlaceholder alloc] init];
    self.email.placeholder = @"Email";
    self.email.keyboardType = UIKeyboardTypeEmailAddress;
    self.email.autocorrectionType = UITextAutocorrectionTypeNo;
    self.email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.email.returnKeyType = UIReturnKeyNext;
    self.email.keyboardAppearance = UIKeyboardAppearanceDark;

    self.password = [[ARSecureTextFieldWithPlaceholder alloc] init];
    self.password.placeholder = @"Password";
    self.password.secureTextEntry = YES;
    self.password.returnKeyType = UIReturnKeyJoin;
    self.password.keyboardAppearance = UIKeyboardAppearanceDark;

    self.containerView = [[UIView alloc] init];
    [self.view addSubview:self.containerView];
    [self.containerView alignCenterXWithView:self.view predicate:nil];
    NSString *centerYOffset = [UIDevice isPad] ? @"0" : @"-30";
    [self.containerView alignCenterYWithView:self.view predicate: NSStringWithFormat(@"%@@750", centerYOffset)];
    self.keyboardConstraint = [[self.containerView alignBottomEdgeWithView:self.view predicate:@"<=0@1000"] lastObject];
    [self.containerView constrainWidth:@"280"];

    [@[self.name, self.email, self.password] each:^(ARTextFieldWithPlaceholder *textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.delegate = self;
        [self.containerView addSubview:textField];
        [textField constrainWidth:@"280" height:@"30"];
        [textField alignLeading:@"0" trailing:@"0" toView:self.containerView];
        [textField ar_extendHitTestSizeByWidth:0 andHeight:10];
    }];
    [self.name alignTopEdgeWithView:self.containerView predicate:@"0"];
    [self.email constrainTopSpaceToView:self.name predicate:@"20"];
    [self.password constrainTopSpaceToView:self.email predicate:@"20"];
    [self.password alignBottomEdgeWithView:self.containerView predicate:@"0"];

    ARSpinner *spinner = [[ARSpinner alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    spinner.alpha = 0;
    spinner.center = self.view.center;
    spinner.spinnerColor = [UIColor whiteColor];
    self.loadingSpinner = spinner;
    [self.view addSubview:spinner];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];

    [super viewDidLoad];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.keyboardConstraint.constant = -keyboardSize.height - ([UIDevice isPad] ? 20 : 10);
    [UIView animateIf:YES duration:duration :^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGFloat duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.keyboardConstraint.constant = 0;
    [UIView animateIf:YES duration:duration :^{
        [self.view layoutIfNeeded];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.name becomeFirstResponder];
    [super viewDidAppear:animated];
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

- (BOOL)canSubmit
{
    return self.email.text.length
            && self.name.text.length
            && [self.email.text containsString:@"@"]
            && self.password.text.length >= 6;
}


- (void)back:(id)sender
{
    [self.delegate popViewControllerAnimated:YES];
}

- (void)setFormEnabled:(BOOL)enabled
{
    [@[self.name, self.email, self.password] each:^(ARTextFieldWithPlaceholder *textField) {
        textField.enabled = enabled;
        textField.alpha = enabled ? 1 : 0.3;
    }];

    [self.navbar.forward setEnabled:enabled animated:YES];;

    if (enabled) {
        [self.loadingSpinner fadeOutAnimated:YES];
    } else {
        [self.loadingSpinner fadeInAnimated:YES];
    }
}

- (NSString *)existingAccountSource:(NSDictionary *)JSON
{
    NSArray *providers = JSON[@"providers"];
    if (providers) {
        return [providers.first lowercaseString];
    }
    NSString *message = JSON[@"text"];
    if (!message) {
        return @"email";
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"A user with this email has already signed up with ([A-Za-z]+)." options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:message options:0 range:NSMakeRange(0, message.length)];
    if ([match numberOfRanges] != 2) {
        return @"email";
    }
    NSString *provider = [message substringWithRange:[match rangeAtIndex:1]];
    return [provider lowercaseString];
}

- (void)submit:(id)sender
{
    [self setFormEnabled:NO];

    NSString *username = self.email.text;
    NSString *password = self.password.text;

    @weakify(self);
    [[ARUserManager sharedManager] createUserWithName:self.name.text email:username password:password success:^(User *user) {
        @strongify(self);
        [self loginWithUserCredentials];
    } failure:^(NSError *error, id JSON) {
        @strongify(self);
        if (JSON
            && [JSON isKindOfClass:[NSDictionary class]]
            && ([JSON[@"error"] isEqualToString:@"User Already Exists"]
                || [JSON[@"error"] isEqualToString:@"User Already Invited"])) {
                NSString *source = [self existingAccountSource:JSON];
                [self accountExists:source];
            [ARAnalytics event:ARAnalyticsUserAlreadyExistedAtSignUp];

        } else {
            [self setFormEnabled:YES];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn’t create your account" message:@"Please check your email address & password" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alert show];

            [self.email becomeFirstResponder];
        }
    }];
}

- (void)loginWithUserCredentials
{
    NSString *username = self.email.text;
    NSString *password = self.password.text;

    @weakify(self);
   [[ARUserManager sharedManager] loginWithUsername:username password:password successWithCredentials:nil
     gotUser:^(User *currentUser) {
        @strongify(self);
        [self.delegate signupDone];
        [ARAnalytics event:ARAnalyticsUserSignedIn withProperties:@{ @"context" : ARAnalyticsUserContextEmail }];

    } authenticationFailure:^(NSError *error) {
        @strongify(self);
        [self setFormEnabled:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn’t Log In" message:@"Please check your email and password." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];

    } networkFailure:^(NSError *error) {
        @strongify(self);
        [self setFormEnabled:YES];
        [self performSelector:_cmd withObject:self afterDelay:3];
        [ARNetworkErrorManager presentActiveErrorModalWithError:error];
    }];
}

- (void)accountExists:(NSString *)source
{
    NSString *message;
    NSInteger tag;
    if ([source isEqualToString:@"email"]) {
        message= [NSString stringWithFormat:@"An account already exists for the email address \"%@\".", self.email.text];
        tag = EMAIL_TAG;
    } else {
        message= [NSString stringWithFormat:@"An account already exists for the email address \"%@\". Please log in via %@.",
                  self.email.text,
                  [source capitalizedString]];
        tag = SOCIAL_TAG;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Account Already Exists" message:message delegate:self cancelButtonTitle:@"Log In" otherButtonTitles:nil];
    alert.tag = tag;
    [alert show];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:nil];
}

#pragma mark -
#pragma mark UITextField

- (void)textChanged:(NSNotification *)n
{
    [self.navbar.forward setEnabled:[self canSubmit] animated:YES];
}

#pragma mark - delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.name) {
        [self.email becomeFirstResponder];
        return YES;
    } else if (textField == self.email) {
        [self.password becomeFirstResponder];
        return YES;
    } else if ([self canSubmit]) {
        [self submit:nil];
        return YES;
    }
    return NO;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *email = nil;
    if (alertView.tag == EMAIL_TAG) {
        email = self.email.text;
    }
    [self.delegate logInWithEmail:email];
}

@end
