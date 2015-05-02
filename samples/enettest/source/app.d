module app;

import std.stdio;

import unecht;
import derelict.enet.enet;
import derelict.imgui.imgui;

alias OnDataCallback = void delegate(ubyte*,size_t);

///
@UEDefaultInspector!TestLogic
final class TestLogic : UEComponent
{
    mixin(UERegisterComponent!());

    bool isServer=false;

    private ENetHost* server=null;
    private ENetHost* client=null;
    private ENetPeer* clientPeer=null;
    private string chat;

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        DerelictENet.load();

        enet_initialize();

        auto enetVersion = enet_linked_version();

        writefln("enet: %s.%s.%s",ENET_VERSION_GET_MAJOR(enetVersion),ENET_VERSION_GET_MINOR(enetVersion),ENET_VERSION_GET_PATCH(enetVersion));
    }

    override void onDestroy() {
        super.onDestroy;

        if(server)
        {
            enet_host_destroy(server);
            server = null;
        }

        if(client)
        {
            enet_host_destroy(client);
            enet_peer_reset (clientPeer);

            client = null;
        }

        enet_deinitialize();
    }

    override void onUpdate() {
        super.onUpdate;

        if(isServer && !server)
        {
            ENetAddress address;
            
            /* Bind the server to the default localhost.     */
            /* A specific host address can be specified by   */
            /* enet_address_set_host (& address, "x.x.x.x"); */
            address.host = ENET_HOST_ANY;
            /* Bind the server to port 1234. */
            address.port = 1234;
            
            server = enet_host_create (& address /* the address to bind the server host to */, 
                32      /* allow up to 32 clients and/or outgoing connections */,
                2      /* allow up to 2 channels to be used, 0 and 1 */,
                0      /* assume any amount of incoming bandwidth */,
                0      /* assume any amount of outgoing bandwidth */);
            
            assert(server);

            writefln("server started: %s",server.address);
        }
        else if(isServer && server)
        {
            updatePeer(server, &onDataServer);

            renderEnetHostGUI(server, "server");
        }

        if(!client)
        {
            client = enet_host_create (null /* create a client host */,
                1 /* only allow 1 outgoing connection */,
                2 /* allow up 2 channels to be used, 0 and 1 */,
                57600 / 8 /* 56K modem with 56 Kbps downstream bandwidth */,
                14400 / 8 /* 56K modem with 14 Kbps upstream bandwidth */);

            ENetAddress address;

            /* Connect to some.server.net:1234. */
            enet_address_set_host (&address, "127.0.0.1");
            address.port = 1234;
            /* Initiate the connection, allocating the two channels 0 and 1. */
            clientPeer = enet_host_connect (client, &address, 2, 0);    

            writefln("client started: %s",clientPeer.address);
        }
        else
        {
            updatePeer(client, &onDataClient);

            renderEnetHostGUI(client,"client");

            ig_Begin("chat");
            scope(exit) ig_End();

            static string currentInput;
            if(UEGui.InputText!128("send",currentInput))
            {
                sendChat(currentInput);
                currentInput.length = 0;
            }

            UEGui.Text(chat);
        }
    }

    private void onDataServer(ubyte* data, size_t length)
    {
        /* Create a reliable packet */
        ENetPacket* packet = enet_packet_create (data, 
            length, 
            ENET_PACKET_FLAG_RELIABLE);
        
        /* Send the packet to the peer over channel id 0. */
        /* One could also broadcast the packet by         */
        /* enet_host_broadcast (host, 0, packet);         */
        enet_host_broadcast (server, 0, packet);
        
        /* One could just use enet_host_service() instead. */
        enet_host_flush (server);
    }

    private void onDataClient(ubyte* data, size_t length)
    {
        chat = to!string(cast(char[])data[0..length]) ~ "\n" ~ chat;
    }

    private void sendChat(string text)
    {
        /* Create a reliable packet */
        ENetPacket* packet = enet_packet_create (text.ptr, 
            text.length, 
            ENET_PACKET_FLAG_RELIABLE);
            
        /* Send the packet to the peer over channel id 0. */
        /* One could also broadcast the packet by         */
        /* enet_host_broadcast (host, 0, packet);         */
        enet_peer_send (clientPeer, 0, packet);

        /* One could just use enet_host_service() instead. */
        enet_host_flush (client);
    }

    private void renderEnetHostGUI(ENetHost* host, const(char)* name)
    {
        ig_Begin(name);
        scope(exit) ig_End();
        
        ig_Text("incomingBandwidth: %d",        host.incomingBandwidth);
        ig_Text("outgoingBandwidth: %d",        host.outgoingBandwidth);
        ig_Text("bandwidthThrottleEpoch: %d",   host.bandwidthThrottleEpoch);
        ig_Text("mtu: %d",                      host.mtu);
        ig_Text("totalSentData: %d",            host.totalSentData);
        ig_Text("totalSentPackets: %d",         host.totalSentPackets);
        ig_Text("totalReceivedData: %d",        host.totalReceivedData);
        ig_Text("totalReceivedPackets: %d",     host.totalReceivedPackets);
        ig_Text("connectedPeers: %d",           host.connectedPeers);
        ig_Text("peerCount: %d",                host.peerCount);
        ig_Text("bandwidthLimitedPeers: %d",    host.bandwidthLimitedPeers);

        foreach(i, p; host.peers[0..host.peerCount])
        {
            if(p.state != ENET_PEER_STATE_DISCONNECTED)
            {
                if(UEGui.TreeNode(format("peer %s",i)))
                {
                    UEGui.Text(format("state: %s",p.state));
                    ig_Text("incomingBandwidth: %d", p.incomingBandwidth);
                    ig_Text("outgoingBandwidth: %d", p.outgoingBandwidth);
                    ig_Text("incomingDataTotal: %d", p.incomingDataTotal);
                    ig_Text("outgoingDataTotal: %d", p.outgoingDataTotal);
                    ig_Text("packetsSent: %d", p.packetsSent);
                    ig_Text("packetsLost: %d", p.packetsLost);
                    ig_Text("pingInterval: %d", p.pingInterval);
                    ig_Text("lastRoundTripTime: %d", p.lastRoundTripTime);
                    ig_Text("lowestRoundTripTime: %d", p.lowestRoundTripTime);
                    ig_Text("lastRoundTripTimeVariance: %d", p.lastRoundTripTimeVariance);
                    ig_Text("highestRoundTripTimeVariance: %d", p.highestRoundTripTimeVariance);
                    ig_Text("roundTripTime: %d", p.roundTripTime);
                    ig_Text("mtu: %d", p.mtu);

                    ig_TreePop();
                }
            }
        }
    }

    private void updatePeer(ENetHost* peer, scope OnDataCallback onData)
    {
        ENetEvent event;
        while (enet_host_service (peer, &event, 0) > 0)
        {
            final switch (event.type)
            {
                case ENET_EVENT_TYPE_CONNECT:
                    writefln("peer connected: %s",event.peer.address);
                    break;

                case ENET_EVENT_TYPE_RECEIVE:
                    onData(event.packet.data, event.packet.dataLength);

                    /* Clean up the packet now that we're done using it. */
                    enet_packet_destroy (event.packet);
                    break;

                case ENET_EVENT_TYPE_DISCONNECT:
                    writefln("peer disconnected: %s",event.peer.address);
                    /* Reset the peer's client information. */
                    event.peer.data = null;
                    break;

                case ENET_EVENT_TYPE_NONE:
                    writefln("peer event: %s",event.type);
                    enet_packet_destroy (event.packet);
                    break;
            }
        }
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();
        }
    }
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - enet test sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create("game");
        newE.addComponent!TestLogic;

		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,15,-20);
        newE2.sceneNode.angles = vec3(30,0,0);

        import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
	};
}