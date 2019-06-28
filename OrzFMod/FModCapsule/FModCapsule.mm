

#import "FModCapsule.h"
#include "fmod_studio.hpp"
#include "fmod.hpp"
#include "common.h"
#include "fmod_errors.h"



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
        
        [FModCapsule sharedSingleton].fmodsystem->loadBankFile(GetMediaPath([bankPath UTF8String]), FMOD_STUDIO_LOAD_BANK_NONBLOCKING, &newBankPointer);
        newBank.bankPointer = newBankPointer;
        [FModCapsule sharedSingleton].localBank = newBankPointer;
        
    }
    
    return newBank;
}
    
    
    @end

@implementation FModEvent
    @synthesize eventDescriptionPointer = _eventDescriptionPointer;
    @synthesize eventInstancePointer = _eventInstancePointer;
    FModEvent* newEvent = [[FModEvent alloc] init];
-(id)playBankWithPath:(NSString*)eventPath {
    
    
    if (newEvent) {
        FMOD_STUDIO_LOADING_STATE state;
        FMOD::Studio::ID eventID = {0};
        int count;
        [FModCapsule sharedSingleton].fmodsystem->lookupID([eventPath UTF8String], &eventID);
        [FModCapsule sharedSingleton].localBank->getEventCount(&count);
        [FModCapsule sharedSingleton].localBank->getLoadingState(&state);
        FMOD::Studio::EventDescription* newEventPointer = NULL;
        [FModCapsule sharedSingleton].fmodsystem->getEventByID(&eventID, &newEventPointer);
        newEventPointer->loadSampleData();
        newEvent.eventDescriptionPointer = newEventPointer;
        FMOD::Studio::EventInstance* newEventInstance = NULL;
        newEvent.eventDescriptionPointer->createInstance(&newEventInstance);
        
        newEvent.eventInstancePointer = newEventInstance;
        if(newEvent.eventInstancePointer != NULL) {
            newEvent.eventInstancePointer->start();
        }
    }
    
    return newEvent;
}
    
-(void)play {
    if (_eventInstancePointer == NULL && _eventDescriptionPointer != NULL) {
        
        FMOD::Studio::EventInstance* newEventInstance = NULL;
        _eventDescriptionPointer->createInstance(&newEventInstance);
        
        _eventInstancePointer = newEventInstance;
    }
    
    if(_eventInstancePointer != NULL) {
        _eventInstancePointer->start();
    }
}
    
-(void)stop {
    newEvent.eventInstancePointer->stop(FMOD_STUDIO_STOP_IMMEDIATE);
}
    
    
    
    @end

@implementation FModCapsule
    @synthesize fmodsystem = _fmodsystem;
    
-(instancetype)init
    {
        if(self = [super init])
        {
            [self createSystem];
        }
        return self;
    }
    
-(void)createSystem {
    
    channel = 0;
    extradriverdata = 0;
    sound = 0;
    result = FMOD_OK;
    
    result = FMOD::System_Create(&system);
    
    
    result = system->getVersion(&version);
    
    
    if (version < FMOD_VERSION)
    {
        NSLog(@"FMOD lib version %08x doesn't match header version %08x", version, FMOD_VERSION);
        return;
    }
    
    Common_Init(&extradriverdata);
    
    result = system->init(32, FMOD_INIT_NORMAL, extradriverdata);
    
}
    
-(void)playStreamWithFilePath:(NSString *)filePath
    {
        [self releaseSound];
        
        result = system->createStream(filePath.UTF8String, FMOD_LOOP_NORMAL | FMOD_2D, 0, &sound);
        
        
        result = sound->getNumSubSounds(&numsubsounds);
        
        
        if (numsubsounds)
        {
            sound->getSubSound(0, &sound_to_play);
            
        }
        else
        {
            sound_to_play = sound;
        }
        
        result = system->playSound(sound_to_play, 0, false, &channel);
        
    }
-(void)play
    {
        if(channel)
        {
            bool isPaused = false;
            channel->getPaused(&isPaused);
            if(isPaused)
            {
                channel->setPaused(false);
            }
        }
    }
    
-(void)pause
    {
        if(channel)
        {
            bool isPlaying = false;
            channel->isPlaying(&isPlaying);
            if(isPlaying)
            {
                channel->setPaused(true);
            }
            
        }
    }
-(void)close
    {
        [self releaseSound];
        [self releaseSystem];
    }
    
-(void)releaseSound {
    if(sound)
    {
        result = sound->release();
        
        sound = 0;
    }
}
    
-(void)releaseSystem {
    if(system)
    {
        result = system->close();
        
        
        result = system->release();
        
    }
}
-(void)stop
    {
        if(channel)
        {
            channel->stop();
        }
    }
    
-(BOOL)isPlaying {
    if(channel)
    {
        bool isPlaying = false;
        channel->isPlaying(&isPlaying);
        if(isPlaying) {
            return YES;
        }
    }
    return NO;
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
        
        [[FModCapsule displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [FModCapsule sharedSingleton].fmodsystem = newSystem;
    }
    
-(void)loadBankWithPath:(NSString*)bankPath
    {
        FModBank* bank = [FModBank bankWithPath:bankPath];
        if (bank.bankPointer){
            [[FModCapsule sharedSingleton].loadedBanks addObject:bank];
        }
    }
    
    
    
    @end
