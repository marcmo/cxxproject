package com.flopcode.graphstream.client;

import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;

public class Main {
	public static void main(String[] args) throws Exception {
		Socket s = new Socket("127.0.0.1", 31217);
		PrintWriter out = new PrintWriter(new OutputStreamWriter(
				s.getOutputStream(), "UTF-8"));
		out.println("SetStylesheet(node{fill-color: red;}node.blue{fill-color:blue;})");
		for (int i = 0; i < 100; i++) {
			out.println("AddVertex(" + i + ")");
			if (i %2 == 0) {
				out.println("SetClass(" + i + ",blue)");
			}
			out.flush();
		}
		for (int i = 0; i < 99; i++) {
			out.println("AddEdge(" + i + "," + (i + 1) + ")");
			out.flush();
		}
		out.println("AddEdge(99,0)");
		out.flush();
		
		Thread.sleep(2000);

		out.println("Clear()");
		out.flush();
	}
}
