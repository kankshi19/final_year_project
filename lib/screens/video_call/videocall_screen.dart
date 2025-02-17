import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  

  const VideoCallScreen({Key? key, required this.callId, required String chatId}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _startCall();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _startCall() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    final mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    stream.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, stream);
    });

    setState(() {
      _localRenderer.srcObject = stream;
    });

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    _peerConnection?.onIceCandidate = (candidate) {
      FirebaseFirestore.instance
          .collection('video_calls')
          .doc(widget.callId)
          .collection('candidates')
          .add(candidate.toMap());
    };

    DocumentSnapshot callDoc = await FirebaseFirestore.instance
        .collection('video_calls')
        .doc(widget.callId)
        .get();

    if (callDoc.exists) {
      Map<String, dynamic> callData = callDoc.data() as Map<String, dynamic>;
      if (callData['offer'] != null) {
        RTCSessionDescription offer = RTCSessionDescription(callData['offer']['sdp'], callData['offer']['type']);
        await _peerConnection?.setRemoteDescription(offer);

        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        FirebaseFirestore.instance
            .collection('video_calls')
            .doc(widget.callId)
            .update({'answer': answer.toMap()});
      }
    }

    FirebaseFirestore.instance
        .collection('video_calls')
        .doc(widget.callId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        var data = doc.data();
        _peerConnection?.addCandidate(RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
      }
    });
  }

  void _endCall() async {
    await FirebaseFirestore.instance
        .collection('video_calls')
        .doc(widget.callId)
        .update({'status': 'ended'});

    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Call"),
        actions: [
          IconButton(
            icon: Icon(Icons.call_end, color: Colors.red),
            onPressed: _endCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(_remoteRenderer)),
          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 120,
              height: 160,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
        ],
      ),
    );
  }
}
