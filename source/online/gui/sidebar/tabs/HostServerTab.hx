package online.gui.sidebar.tabs;

import haxe.io.Path;
import sys.FileSystem;
import haxe.io.Error;

//TODO force kill server and node.exe
//TODO stop freezing

class HostServerTab extends TabSprite {
    public function new() {
        super('Host Server', 'server');
		tabWidth = 600;
    }

	var logs:TextField;
	var startAndStop:TabButton;
	var updateServer:TabButton;

    override function create() {
        super.create();

		logs = this.createText(0, 0, 16, FlxColor.WHITE);
		addChild(logs);

		startAndStop = new TabButton('start', startAndStopServer);
		startAndStop.x = tabWidth - startAndStop.width - 10;
		startAndStop.y = 10;
		addChild(startAndStop);

		updateServer = new TabButton('update', () -> {
			FileUtils.removeFiles('_server/');
			prepareServer();
		});
		updateServer.x = startAndStop.x;
		updateServer.y = startAndStop.y + startAndStop.height + 10;
		addChild(updateServer);
    }

	override function onShow() {
		super.onShow();

		if (process == null)
			logs.setText('\nYou can host a server locally with the button here! -->\n\nThe server will not be exposed to the public and will\nonly be visible in your local network.\n\n(If you don\'t have NodeJS installed,\nthe game will install it on your system)');
	}

    function startAndStopServer() {
		if (process == null)
			prepareServer();
        else
            stopServer();
    }

    function prepareServer() {
		if (process != null) {
			stopServer();
			return;
		}

		startAndStop.visible = false;
		updateServer.visible = false;

		var npmCheck = new sys.io.Process("npm");
		if (npmCheck.stdout.readAll().toString().trim().length == 0) {
            #if windows
			var nodeDownload = new sys.io.Process("curl https://nodejs.org/dist/v21.6.2/node-v21.6.2-x64.msi -L -o node.msi");
			logProcess(nodeDownload);

			var nodeInstall = new sys.io.Process("msiexec /i node.msi /quiet");
			logProcess(nodeInstall);
            #else
			var fnmDownload = new sys.io.Process("curl --output fnm.sh https://fnm.vercel.app/install");
			logProcess(fnmDownload);

			var fnmInstall = new sys.io.Process("bash fnm.sh");
			logProcess(fnmInstall);

			FileSystem.deleteFile('fnm.sh');
            
			var nodeInstall = new sys.io.Process("fnm install v21.6.2");
			logProcess(nodeInstall);
            #end
        }
		npmCheck.close();

		var cwd = Sys.getCwd();

        if (!FileSystem.exists('_server/')) {
			var serverURL = "https://github.com/Snirozu/Funkin-Online-Server/archive/refs/heads/" + (states.TitleState.inDev ? 'dev' : 'main') + ".zip";

			#if windows
			var downloadServer = new sys.io.Process("curl " + serverURL + " -L -o server.zip");
			logProcess(downloadServer);

			var unzipServer = new sys.io.Process("tar -xf server.zip");
			logProcess(unzipServer);
            #else
			var downloadServer = new sys.io.Process("curl --output server.zip " + serverURL);
			logProcess(downloadServer);

			var unzipServer = new sys.io.Process("unzip server.zip");
			logProcess(unzipServer);
            #end

			FileSystem.deleteFile('server.zip');
			FileSystem.rename('Funkin-Online-Server-' + (states.TitleState.inDev ? 'dev' : 'main'), '_server');

			Sys.setCwd(Path.join([cwd, '_server']));
			var installPackages = new sys.io.Process("npm i");
			Sys.setCwd(cwd);
			logProcess(installPackages);
        }

		logs.setText('Starting the server...');
		startAndStop.icon.bitmapData = GAssets.image('sidebar/exit');

        Thread.run(() -> {
			startServer();
        });
    }

    public static var process:sys.io.Process;

    function startServer() {
		var cwd = Sys.getCwd();

		Sys.setCwd(Path.join([cwd, '_server']));
		process = new sys.io.Process("npm test");
		Sys.setCwd(cwd);

		Waiter.putPersist(() -> {
			startAndStop.visible = true;
			updateServer.visible = false;
		});

        try {
            //it will run forever until the user wants to stop it
			while (process != null && process.exitCode(false) == null) {
                try {
                    var line = process.stdout.readLine();
                    Waiter.putPersist(() -> {
						logs.setText(logs.text + '\n' + line.wrapText(70, 6969, false));
						TextFormats.applyASCII(logs);
                    });
                }
                catch (e:Dynamic) {
                    trace('cras');
                    if (e == Error.Blocked) {
                        // Blocked will be ignored
                        continue;
                    }
                    throw e;
                }
            }
        }
        catch (e:Dynamic) {
            stopServer();
            trace(e);
        }
    }

    public static function stopServer() {
		if (process == null) {
			return;
		}

        trace('killing the server');
		#if windows
		var killServer = new sys.io.Process("taskkill /t /f /PID " + process.getPid());
		#else
		var killServer = new sys.io.Process("pkill -TERM -P " + process.getPid());
		#end
		killServer.close();
		process.close();
		process = null;

		Waiter.putPersist(() -> {
            Alert.alert('Server Stopped!');
			var instance:HostServerTab = cast(SideUI.instance.tabs[SideUI.instance.initTabs.indexOf(HostServerTab)]);
			instance.logs.setText(instance.logs.text + '\n' + 'Server has been stopped!');
			if (instance != null && instance.initialized) {
				instance.startAndStop.icon.bitmapData = GAssets.image('sidebar/start');
				instance.updateServer.visible = true;
			}
        });
    }

	function logProcess(process:sys.io.Process) {
		logs.setText(logs.text + '\n' + process.stdout.readAll().toString().wrapText(70, 6969, false));
		TextFormats.applyASCII(logs);
		trace(process.exitCode());
		process.close();
    }
}