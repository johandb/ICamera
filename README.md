# ICamera
ICamera - Show your iphone camera on laptop/desktop

This is the free software for showing your Iphone camera video on your laptop or desktop.

The only thing you need is a real iPhone or iPad and some software tools as mentioned in the **prerequisites**

## Story
In these days of corona virus I was facing an issue for using a webcam on my laptop. I did not have one on my laptop installed. So I started to write a simple app and server to sent the video frames recorded on my iphone to my laptop.

As I was looking on some example I found out that most of them were using RSTP protocol. Because I do not want to implement
this protocol I decided to sent the frames over **sockets**. Searching in cocoapods I found the BlueSocket library a very good
candidate for sending data over sockets to my server.

Lets talk about the application how it is build and what software I used.

**This application comes in four parts**
- The app for recording the video, using swift on IOS
- The server side written in Java, for receiving the video frames as png files and display it in a JFrame window
- Running the app
- Using a freeware virtual camera device for using in applications like Microsoft Teams or Skype.

## Prerequisites

The following software and devices are used

- Iphone Xs

- Mac OSX 10.15
- IOS 13+
- Swift 5.1

- Java 11 (open jdk zulu version)
- IntelliJ

- SplitCamera

  http://splitcamera.com/
  
  https://splitcam.com/download
  
## TODO

Below is a todo list what features must be implemented

- remove hard coded port numbers, search the network
- compression sending package
- build a windows installer
- Add your own feature :)

## Part 1 : The app

You can find all the sources for the iphone in the IOS folder. I suggest you create your own app 
and copy the sources in your own app. 
The app is using a pod i.e. BlueSocket. The podfile is included in the repository. For using the
BlueSocket library you must install the pod by entering the following command :

- Open a terminal window
- Change to the folder where you created your app for example ICamera
- enter : pod install

This will take a few seconds to install the need library BlueSocket

Next, copy all the sources from this repository from the IOS folder to your apps folder.

Next, You must modify the ViewController class and change the ip adres to some adres
within your wifi network. As default there is the host address : 192.168.1.10 but you
must change it to your network. Also you can change the port number for sending the package.
The default port number is 9000.
**If you find problems on sending packages on app or server side maybe you have to open the
port number in your firewall**

Connect your iphone using your usb cable.

Now your app should be able to build.

## Part 2 : The server side (laptop or desktop)

The server is build with Java. I was using open jdk java version 11 which you can download at

https://www.azul.com/downloads/zulu-community/?architecture=x86-64-bit&package=jdk

You can use any IDE like IntelliJ or Eclipse and build the server. The CameraServer has a main method 
which you can use to start the server.

You must specify the port number where your server is listening for incoming data. For example 
you can start the server using the command.

**java CameraServer 9000**

This means the server is listening for data packets on port 9000.

NOTE: The portnumber must match the portnumber what you specify in your app.


## Part 3 - Running

To start viewing video frames on your laptop/desktop do the following

- start your (java) server 
- start your app

If all goes well you must be seeing video on your window.

Congratulations.

## Part 4 - Virtual Camera Device

The fun part is thar your video window on your server can used as input in the SplitCamera software.

You can download this software from

https://splitcam.com/download

http://splitcamera.com/

It is very easy to use. Just add a screen capture and select the window frame from your java server.

Now you can use your camera in for example **Microsoft Teams**

I hope all works as expected

Happy coding

Johan
