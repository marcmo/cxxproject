package com.flopcode.graphstream.server;

import java.awt.*;
import java.awt.event.ActionEvent;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.DefaultGraph;
import org.graphstream.graph.implementations.SingleGraph;

import com.flopcode.graphstream.utils.Log;
import org.graphstream.ui.graphicGraph.GraphicGraph;
import org.graphstream.ui.layout.Layout;
import org.graphstream.ui.layout.Layouts;
import org.graphstream.ui.layout.springbox.SpringBox;
import org.graphstream.ui.swingViewer.View;
import org.graphstream.ui.swingViewer.Viewer;

import javax.swing.*;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import javax.swing.plaf.basic.BasicSplitPaneUI;

public class GraphStreamServer {
	public interface Command {
		boolean matches(String s);

		void execute(DefaultGraph graph, String s);
	}

	public static abstract class RegexCommand implements Command {
		protected final Pattern fPattern;

		public RegexCommand(Pattern p) {
			fPattern = p;
		}

		@Override
		public boolean matches(String s) {
			return fPattern.matcher(s).matches();
		}

		@Override
		public void execute(DefaultGraph graph, String s) {
			Matcher m = fPattern.matcher(s);
			if (m.matches()) {
				matched(graph, m);
			}
		}

		protected abstract void matched(DefaultGraph graph, Matcher m);
	}

	public static class AddVertexCommand extends RegexCommand {
		public AddVertexCommand() {
			super(Pattern.compile("AddVertex\\((.*)\\)"));
		}

		@Override
		public void matched(DefaultGraph graph, Matcher m) {
			String nodeId = m.group(1);
			if (graph.getNode(nodeId) == null) {
				Node n = graph.addNode(nodeId);
				n.addAttribute("ui.label", nodeId);
				n.addAttribute("ui.fill-color", "#00ff00");
			} else {
				Log.w("node already in graph");
			}
		}
	}
	
	public static class SetStylesheetCommand extends RegexCommand {
		public SetStylesheetCommand() {
			super(Pattern.compile("SetStylesheet\\((.*)\\)"));
		}
		@Override
		protected void matched(DefaultGraph graph, Matcher m) {
			graph.setAttribute("ui.stylesheet", m.group(1));
		}
	}

	public static class SetClassCommand extends RegexCommand {
		public SetClassCommand() {
			super(Pattern.compile("SetClass\\((.*?),(.*?)\\)"));
		}
		@Override
		protected void matched(DefaultGraph graph, Matcher m) {
			String idOfNode = m.group(1);
			String clazz = m.group(2);
			Node n = graph.getNode(idOfNode);
			if (n == null) {
				Log.w("could not find " + idOfNode + " when setting class " + clazz);
				return;
			}
			n.setAttribute("ui.class", clazz);
		}
	}
	public static class AddEdgeCommand extends RegexCommand {
		public AddEdgeCommand() {
			super(Pattern.compile("AddEdge\\((.*?),(.*?)\\)"));
		}

		@Override
		protected void matched(DefaultGraph graph, Matcher m) {
			String idOfNode1 = m.group(1);
			Node n1 = graph.getNode(idOfNode1);
			String idOfNode2 = m.group(2);
			Node n2 = graph.getNode(idOfNode2);
			if (n1 == null) {
				Log.w("could not find " + idOfNode1 + " when creating edge");
				return;
			}
			if (n2 == null) {
				Log.w("could not find " + idOfNode2 + " when creating edge");
				return;
			}
			String edgeId = idOfNode1 + "->" + idOfNode2;
			if (graph.getEdge(edgeId) != null) {
				Log.w("edge already registered '" + edgeId + "'");
				return;
			}
			graph.addEdge(edgeId, idOfNode1, idOfNode2);
		}
	}

	public static class ClearCommand extends RegexCommand {
		public ClearCommand() {
			super(Pattern.compile("Clear\\(\\)"));
		}

		@Override
		public void matched(DefaultGraph graph, Matcher m) {
			graph.clear();
		}
	}

	public static class Commands {
		List<Command> fCommands = new ArrayList<Command>();

		public Commands() {
			fCommands.add(new SetStylesheetCommand());
			fCommands.add(new AddVertexCommand());
			fCommands.add(new AddEdgeCommand());
			fCommands.add(new SetClassCommand());
			fCommands.add(new ClearCommand());
		}

		public void execute(DefaultGraph graph, String s) {
			int exeCount = 0;
			for (Command command : fCommands) {
				if (command.matches(s)) {
					command.execute(graph, s);
					exeCount++;
				}
			}
			if (exeCount == 0) {
				Log.w("no command found for command: '" + s + "'");
			}
		}

	}

	public class GraphStreamServerClient {
		public GraphStreamServerClient(InputStream inputStream,
				OutputStream outputStream) throws Exception {
			Commands commands = new Commands();
			BufferedReader r = new BufferedReader(new InputStreamReader(
					inputStream, "UTF-8"), 8192);
			String s = r.readLine();
			while (s != null) {
				commands.execute(fGraph, s);
				s = r.readLine();
			}
		}
	}

	private DefaultGraph fGraph;

	public GraphStreamServer() throws Exception {
    ServerSocket s = new ServerSocket(31217);
  	fGraph = new SingleGraph("Tutorial 1");
    final Viewer v = new Viewer(fGraph, Viewer.ThreadingModel.GRAPH_IN_ANOTHER_THREAD);
    JFrame root = new JFrame("GraphStream View");
    root.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

    final View view = v.addDefaultView(false);
    view.setMinimumSize(new Dimension(300, 300));
    view.setPreferredSize(new Dimension(300, 300));

    final Layout l = new SpringBox(false) {
      @Override
      public double getStabilization() {
        if(lastElementCount == countElements()) {
          return Math.max(0.0, 1.0 - 50 * maxMoveLength);
		    }
    		lastElementCount = countElements();
        return 0.0;
      }
      private int countElements() {
        return nodes.getParticleCount()+edges.size();
      }
    };
    l.setStabilizationLimit(0.9);
    v.enableAutoLayout(l);

    root.getContentPane().add(view, BorderLayout.CENTER);

    Box controls = Box.createHorizontalBox();
    final JSlider zoomSlider = new JSlider(1, 200, 100);
    zoomSlider.addChangeListener(new ChangeListener() {
      @Override
      public void stateChanged(ChangeEvent changeEvent) {
        int i = zoomSlider.getValue();
        view.setViewPercent(100.0/i);
      }
    });
    controls.add(zoomSlider);
    controls.add(new JButton(new AbstractAction("one step") {
      @Override
      public void actionPerformed(ActionEvent actionEvent) {
        System.out.println("l.getStabilization() = " + l.getStabilization());
        l.compute();
      }
    }));
    controls.add(new JButton(new AbstractAction("shake") {
      @Override
      public void actionPerformed(ActionEvent actionEvent) {
        System.out.println("l.getStabilization() = " + l.getStabilization());
        l.shake();
      }
    }));
    root.getContentPane().add(controls, BorderLayout.SOUTH);
    root.pack();
    root.setVisible(true);
		while (true) {
			Socket clientSocket = s.accept();
			new GraphStreamServerClient(clientSocket.getInputStream(),
					clientSocket.getOutputStream());
		}
	}

	public static void main(String args[]) throws Exception {
		new GraphStreamServer();
	}
}
