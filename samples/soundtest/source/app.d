module app;

import std.stdio;

import unecht;
import derelict.fmod.fmod;

///
final class CloseLogic : UEComponent
{
    mixin(UERegisterObject!());

    private SoundSource snd;

    override void onCreate() {
        super.onCreate;
        
        registerEvent(UEEventType.key, &OnKeyEvent);

        snd = entity.addComponent!SoundSource;
        snd.play();
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();

            if(_ev.keyEvent.key == UEKey.space)
                snd.play();
        }
    }
}

///
final class SoundSource : UEComponent
{
    mixin(UERegisterObject!());

    static immutable string testSound = import("beep.wav");

    private FMOD_SOUND* snd;
    private FMOD_CHANNEL* channel;
    
    override void onCreate() {
        super.onCreate;

        loadMemory(testSound);
    }

    void play()
    {
        auto res = FMOD_System_PlaySound(SoundSystem.fmod, snd, null, false, &channel);

        assert(res==FMOD_RESULT.FMOD_OK);

        writefln("play: %s",channel);
    }

    private void loadMemory(string content)
    {
        FMOD_CREATESOUNDEXINFO info;
        info.cbsize = FMOD_CREATESOUNDEXINFO.sizeof;
        info.length = cast(uint)content.length;

        auto res = FMOD_System_CreateSound(SoundSystem.fmod, content.ptr, FMOD_OPENMEMORY, &info, &snd);

        assert(res==FMOD_RESULT.FMOD_OK, format("FMOD_System_CreateSound: %s",res));
    }
}

///
final class SoundSystem : UEComponent
{
    mixin(UERegisterObject!());

    public static FMOD_SYSTEM* fmod;

    override void onCreate() {
        super.onCreate;

        DerelictFmod.load();

        auto resCreate = FMOD_System_Create(&fmod);
        assert(resCreate==FMOD_RESULT.FMOD_OK);

        uint fmodversion;
        FMOD_System_GetVersion(fmod,&fmodversion);

        writefln("fmod v: %s (%s)",fmodversion, FMOD_VERSION);

        assert(fmodversion >= FMOD_VERSION);

        {
            int drivercnt;
            FMOD_System_GetNumDrivers(fmod, &drivercnt);

            foreach(i; 0..drivercnt)
            {
                char[64] name;
                FMOD_GUID guid;
                int sampleRate;
                FMOD_SPEAKERMODE speakermode;
                int speakermodeChannels;
                FMOD_System_GetDriverInfo(fmod,i,name.ptr,64,&guid,&sampleRate,&speakermode,&speakermodeChannels);

                writefln("fmod driver [%s]: (%s,%s,%s,%s)",i,to!string(name),sampleRate,speakermode,speakermodeChannels);
            }
        }

        void* extradriverData;
        auto resInit = FMOD_System_Init(fmod, 32, FMOD_INIT_NORMAL, extradriverData);
        assert(resInit==FMOD_RESULT.FMOD_OK);
    }

    override void onUpdate() {
        super.onUpdate;

        FMOD_System_Update(fmod);
    }

    override void onDestroy() {
        super.onDestroy;

        FMOD_System_Close(fmod);

        FMOD_System_Release(fmod);

        DerelictFmod.unload();
    }
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - enet test sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create("game");
        newE.addComponent!SoundSystem;
        newE.addComponent!CloseLogic;

		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,15,-20);
        newE2.sceneNode.angles = vec3(30,0,0);

        import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
	};
}