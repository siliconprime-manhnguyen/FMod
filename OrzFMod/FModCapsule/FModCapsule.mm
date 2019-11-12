

#import "FModCapsule.h"
#include "fmod_studio.hpp"
#include "fmod.hpp"
#include "common.h"
#include "fmod_errors.h"
#import <AVFoundation/AVAudioSession.h>


const char *GetMediaPath(const char *fileName)
{
    return [[NSString stringWithFormat:@"%@/%s", [[NSBundle mainBundle] resourcePath], fileName] UTF8String];
}


@interface FModBank : NSObject

@property (nonatomic, readwrite, assign) FMOD::Studio::Bank* bankPointer;

@end

@interface FModEvent ()

@property (nonatomic, readwrite, assign) FMOD::Studio::EventDescription* eventDescriptionPointer;
@property (nonatomic, readwrite, assign) FMOD::Studio::EventInstance* eventInstancePointer;

@end

@interface FModCapsule ()
{
    FMOD::System     *system;
    FMOD::Sound      *sound, *sound_to_play;
    FMOD::Channel    *channel;
    FMOD_RESULT       result;
    unsigned int      version;
    void             *extradriverdata;
    int               numsubsounds;
}
+(FModCapsule *)sharedSingleton;
@property (nonatomic, readwrite, assign) FMOD::Studio::System* fmodsystem;
@property (nonatomic, readwrite, assign) FMOD::Studio::Bank* localBank;
@property NSMutableArray* loadedBanks;
@property NSMutableArray* loadedEvents;

@end


@implementation FModBank
@synthesize bankPointer = _bankPointer;

+(id)bankWithPath:(NSString*)bankPath {
    
    FModBank* newBank = [[FModBank alloc] init];
    
    if (newBank) {
        FMOD::Studio::Bank* newBankPointer = NULL;
        
        [FModCapsule sharedSingleton].fmodsystem->loadBankFile([bankPath UTF8String], FMOD_STUDIO_LOAD_BANK_NONBLOCKING, &newBankPointer);
        [FModCapsule sharedSingleton].fmodsystem->flushCommands();
        newBankPointer->loadSampleData();
        newBank.bankPointer = newBankPointer;
        [FModCapsule sharedSingleton].localBank = newBankPointer;
    }
    
    return newBank;
}

@end

@implementation FModEvent
@synthesize eventDescriptionPointer = _eventDescriptionPointer;
@synthesize eventInstancePointer = _eventInstancePointer;

-(void)playBankWithPath:(NSString*)eventPath volume:(float)volume{
    FMOD::Studio::EventDescription* newEventPointer = NULL;
    [FModCapsule sharedSingleton].fmodsystem->getEvent([eventPath UTF8String], &newEventPointer);
    _eventDescriptionPointer = newEventPointer;
    FMOD::Studio::EventInstance* newEventInstance = NULL;
    _eventDescriptionPointer->createInstance(&newEventInstance);
    
    _eventInstancePointer = newEventInstance;
    if(_eventInstancePointer != NULL) {
        _eventInstancePointer->setVolume(volume);
        _eventInstancePointer->start();
        [[FModCapsule sharedSingleton] update];
    }
}

-(void)play:(float)volume {
    if (_eventInstancePointer == NULL) {
        FMOD::Studio::EventInstance* newEventInstance = NULL;
        _eventDescriptionPointer->createInstance(&newEventInstance);
        _eventInstancePointer = newEventInstance;
    }
    
    if(_eventInstancePointer != NULL) {
        _eventInstancePointer->setVolume(volume);
        _eventInstancePointer->start();
        [[FModCapsule sharedSingleton] update];
    }
}

-(void)stop {
    _eventInstancePointer->stop(FMOD_STUDIO_STOP_IMMEDIATE);
    [[FModCapsule sharedSingleton] update];
}

-(void)releaseSound {
    _eventInstancePointer->release();
    _eventDescriptionPointer->releaseAllInstances();
}

@end

@implementation FModCapsule
@synthesize fmodsystem = _fmodsystem;

-(instancetype)init
{
    if(self = [super init])
    {
    }
    return self;
}

//Static singleton access
+(FModCapsule *)sharedSingleton
{
    static FModCapsule *sharedSingleton;
    
    @synchronized(self)
    {
        if (!sharedSingleton) {
            sharedSingleton = [[FModCapsule alloc] init];
            sharedSingleton.loadedBanks = [NSMutableArray array];
            sharedSingleton.loadedEvents = [NSMutableArray array];
        }
        
        return sharedSingleton;
    }
}


+(CADisplayLink *)displayLink
{
    static CADisplayLink* displayLink = nil;
    
    if (displayLink == nil)
    {
        displayLink = [CADisplayLink displayLinkWithTarget:[FModCapsule sharedSingleton] selector:@selector(update)];
    }
    
    return displayLink;
}


-(void)update
{
    [FModCapsule sharedSingleton].fmodsystem->update();
}


-(void)initializeFModSystem
{
    FMOD::Studio::System* newSystem;
    
    FMOD::Studio::System::create(&newSystem);
    
    newSystem->initialize(32, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, NULL);
    
    [FModCapsule sharedSingleton].fmodsystem = newSystem;
}

-(void)releaseSystemFmod
{
    for (int i = 0; i < [FModCapsule sharedSingleton].loadedBanks.count; i++) {
        FModBank* bank = (FModBank*)[FModCapsule sharedSingleton].loadedBanks[i];
        bank.bankPointer->unloadSampleData();
        bank.bankPointer->unload();
    }
    [FModCapsule sharedSingleton].fmodsystem->unloadAll();
    [FModCapsule sharedSingleton].fmodsystem->flushCommands();
    [FModCapsule sharedSingleton].fmodsystem->release();
}

-(void)loadBankWithPath:(NSString*)bankPath
{
    FModBank* bank = [FModBank bankWithPath:bankPath];
    if (bank.bankPointer){
        [[FModCapsule sharedSingleton].loadedBanks addObject:bank];
    }
}

-(int)getEventLength:(NSString*)eventPath {
    FMOD::Studio::ID eventID = {0};
    FMOD::Studio::EventDescription* newEventPointer = NULL;
    [FModCapsule sharedSingleton].fmodsystem->lookupID([eventPath UTF8String], &eventID);
    [FModCapsule sharedSingleton].fmodsystem->getEventByID(&eventID, &newEventPointer);
    int length;
    newEventPointer->getLength(&length);
    return length;
}


@end
