package online.s3d.util;

import lime.utils.DataView;
import openfl.media.Sound;
import lime.media.AudioBuffer;
import lime.utils.UInt8Array;

class AudioUtil {
    // stereo audios can't be panned with SoundTransform3D so we have to convert it to mono
    public static function loadMonoSound(path:String):Sound {
        final buffer:AudioBuffer = AudioBuffer.fromFile(path);
        if (buffer == null)
            return null;
        if (buffer.channels != 2 || buffer.data == null)
            return Sound.fromAudioBuffer(buffer);

        final srcData:UInt8Array = buffer.data;
        final totalBytes:Int = srcData.length;
        final bits:Int = buffer.bitsPerSample;
        var monoData:UInt8Array = new UInt8Array(Std.int(totalBytes / 2));

        var srcIndex:Int = 0;
        var destIndex:Int = 0;

        if (bits == 32) {
            final srcView = new DataView(srcData.buffer, srcData.byteOffset, srcData.byteLength);
            final destView = new DataView(monoData.buffer, monoData.byteOffset, monoData.byteLength);

            while (srcIndex < totalBytes) {
                final left:Float = srcView.getFloat32(srcIndex, true);
                final right:Float = srcView.getFloat32(srcIndex + 4, true);

                final monoSample:Float = (left + right) * 0.5;

                destView.setFloat32(destIndex, monoSample, true);

                srcIndex += 8;
                destIndex += 4;
            }
        } 
        else {
            while (srcIndex < totalBytes) {
                var left:Int = srcData[srcIndex] | (srcData[srcIndex + 1] << 8);
                if ((left & 0x8000) != 0) left |= 0xFFFF0000;

                var right:Int = srcData[srcIndex + 2] | (srcData[srcIndex + 3] << 8);
                if ((right & 0x8000) != 0) right |= 0xFFFF0000;

                final monoSample:Int = Std.int((left + right) / 2);

                monoData[destIndex] = monoSample & 0xFF;
                monoData[destIndex + 1] = (monoSample >> 8) & 0xFF;

                srcIndex += 4;
                destIndex += 2;
            }
        }

        final monoBuffer = new AudioBuffer();
        monoBuffer.bitsPerSample = bits;
        monoBuffer.channels = 1;
        monoBuffer.sampleRate = buffer.sampleRate;
        monoBuffer.data = monoData;
        return Sound.fromAudioBuffer(monoBuffer);
    }
}