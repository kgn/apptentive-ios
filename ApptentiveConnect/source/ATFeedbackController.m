//
//  ATFeedbackController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import "ATFeedbackController.h"
#import "ATConnect.h"
#import "ATContactInfoController.h"
#import "ATContactStorage.h"
#import "ATDefaultTextView.h"
#import "ATFeedback.h"

@interface ATFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view;
- (void)setup;
- (void)setupFeedback;
- (void)teardown;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)feedbackChanged:(NSNotification *)notification;
@end

@implementation ATFeedbackController
@synthesize feedback;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ATFeedbackController" bundle:[ATConnect resourceBundle]];
    } else {
        self = [super initWithNibName:@"ATFeedbackController_iPad" bundle:[ATConnect resourceBundle]];
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)setFeedback:(ATFeedback *)newFeedback {
    if (feedback != newFeedback) {
        [feedback release];
        feedback = nil;
        feedback = [newFeedback retain];
        [self setupFeedback];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    if (self.feedback.name) {
        [feedbackView becomeFirstResponder];
    } else {
        [nameField becomeFirstResponder];
    }
}

- (void)viewDidUnload {
    [self teardown];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (IBAction)cancelFeedback:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)nextStep:(id)sender {
    // TODO
    feedback.name = nameField.text;
    feedback.text = feedbackView.text;
    
    ATContactInfoController *vc = [[ATContactInfoController alloc] init];
    vc.feedback = self.feedback;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}
@end


@implementation ATFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view {
    if (view == nameField) {
        [feedbackView becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (void)setup {
    if (!feedback) {
        self.feedback = [[[ATFeedback alloc] init] autorelease];
    }
    [self setupFeedback];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackChanged:) name:UITextViewTextDidChangeNotification object:feedbackView];
    feedbackView.placeholder = NSLocalizedString(@"Feedback", nil);
    self.title = NSLocalizedString(@"Give Feedback", nil);
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Feedback", nil) style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelFeedback:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next Step", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(nextStep:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)setupFeedback {
    if (nameField && (!nameField.text || [@"" isEqualToString:nameField.text]) && feedback.name) {
        nameField.text = feedback.name;
    }
    if (feedbackView && [feedbackView isDefault] && feedback.text) {
        feedbackView.text = feedback.text;
    }
}

- (void)teardown {
    self.feedback = nil;
    [feedbackView release];
    feedbackView = nil;
    [nameField release];
    nameField = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height -= keyboardRect.size.height;
    
    NSTimeInterval duration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    feedbackView.frame = newFrame;
    [UIView commitAnimations];
    [feedbackView flashScrollIndicators];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    NSTimeInterval animationDuration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height += keyboardRect.size.height;
    feedbackView.frame = newFrame;
    
    [UIView commitAnimations];
}

- (void)feedbackChanged:(NSNotification *)notification {
    if (notification.object == feedbackView) {
        self.navigationItem.rightBarButtonItem.enabled = ![@"" isEqualToString:feedbackView.text];
    }
}
@end
