package org.example.camera;

import javax.swing.*;
import java.awt.*;
import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;
import java.util.Arrays;

public class CameraServer extends JFrame {

    private ServerSocket tcpSocket;

    private int port;

    private ImageIcon icon;
    private JLabel imageLabel;

    public CameraServer(final int port) throws Exception {
        this.port = port;

        this.setLayout(new BoxLayout(this.getContentPane(), BoxLayout.PAGE_AXIS));

        URL url = getClass().getResource("/camera.png");
        icon = new ImageIcon(url);

        this.imageLabel = new JLabel(icon);
        this.add(imageLabel, BorderLayout.CENTER);
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        this.setSize(490, 680);
        this.setTitle("IPhone Camera");
        this.setVisible(true);
    }

    public void start() throws Exception {
        this.tcpSocket = new ServerSocket(port);

        while (true) {
            System.out.println("Waiting for IPhone ....");
            Socket clientSocket = tcpSocket.accept();
            System.out.println("Connected : " + clientSocket.getInetAddress().getHostAddress());
            Client client = new Client(clientSocket);
            client.start();
        }
    }

    public class Client extends Thread {

        private Socket socket;

        public Client(Socket socket) {
            this.socket = socket;
        }

        @Override
        public void run() {
            try {
                DataInputStream in = new DataInputStream(new BufferedInputStream(socket.getInputStream()));
                byte b[] = new byte[160 * 1024];
                ByteArrayOutputStream baos = new ByteArrayOutputStream(5 * 1024 * 1024);
                int total = 0;
                int count = 0;
                while (true) {
                    byte[] bf = new byte[9];
                    int size = in.read(bf);
                    if (size == -1) {
                        break;
                    }
                    boolean isRunning = false;
                    if (bf[0] == '@') {
                        String l = new String(bf);
                        total = Integer.parseInt(l.substring(1, 9));
                        isRunning = true;
                    }
                    while (isRunning) {
                        size = in.read(b);
                        if (size == -1) {
                            break;
                        }
                        count += size;
                        if (count >= total) {
                            baos.write(b, 0, size - (count - total));
                            icon = new ImageIcon(baos.toByteArray());
                            RotatedIcon rotatedIcon = new RotatedIcon(icon, RotatedIcon.Rotate.DOWN);
                            imageLabel.setIcon(rotatedIcon);
                            baos.reset();
                            byte[] buf = Arrays.copyOfRange(b, (size - (count - total)), size);
                            if (buf.length < 1) {
                                isRunning = false;
                                count = 0;
                            } else {
                                if (buf.length < 9) {
                                    isRunning = false;
                                    count = 0;
                                    System.out.println("Oops, something went wrong length buf :" + buf.length + ", expected > 9");
                                    in.close();
                                    System.exit(1);
                                } else {
                                    byte[] slice = Arrays.copyOfRange(buf, 9, buf.length);
                                    baos.write(slice);
                                    String l = new String(buf);
                                    total = Integer.parseInt(l.substring(1, 9));
                                    count = slice.length;
                                }
                            }
                        } else {
                            baos.write(b, 0, size);
                        }
                    }
                }
                System.out.println("Disconnected ...");
                in.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Usage : CameraServer <port>");
            System.exit(1);
        }
        try {
            CameraServer server = new CameraServer(Integer.parseInt(args[0]));
            server.start();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
