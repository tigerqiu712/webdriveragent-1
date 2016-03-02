//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import <XCTest/XCApplicationMonitor.h>

@class NSHashTable;

@interface XCApplicationMonitor_OSX : XCApplicationMonitor
{
    NSHashTable *_monitoredApplications;
    NSHashTable *_observedApplications;
}

- (id)allMonitoredApplications;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)handleWorkspaceNotification:(id)arg1;
- (id)monitoredApplicationWithProcessIdentifier:(int)arg1;
- (void)beginMonitoringApplication:(id)arg1;
- (id)_runningApplicationMatchingXCApplication:(id)arg1;
- (void)_updateXCApplication:(id)arg1 fromNSRunningApplication:(id)arg2;
- (id)init;

@end

