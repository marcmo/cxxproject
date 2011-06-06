package com.github.cxxproject.eclipse.graphstream.views;

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

import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.DefaultGraph;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.thread.ThreadProxyPipe;

public class GraphStreamServer {
	public interface Command {
		boolean matches(String s);

		void execute(Graph graph, String s);
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
		public void execute(Graph graph, String s) {
			Matcher m = fPattern.matcher(s);
			if (m.matches()) {
				matched(graph, m);
			}
		}

		protected abstract void matched(Graph graph, Matcher m);
	}

	public static class AddVertexCommand extends RegexCommand {
		public AddVertexCommand() {
			super(Pattern.compile("AddVertex\\((.*)\\)"));
		}

		@Override
		public void matched(Graph graph, Matcher m) {
			String nodeId = m.group(1);
			if (graph.getNode(nodeId) == null) {
				Node n = graph.addNode(nodeId);
				n.addAttribute("ui.label", nodeId);
				n.addAttribute("ui.fill-color", "#00ff00");
			} else {
				System.out.println("node already in graph");
			}
		}
	}

	public static class SetStylesheetCommand extends RegexCommand {
		public SetStylesheetCommand() {
			super(Pattern.compile("SetStylesheet\\((.*)\\)"));
		}

		@Override
		protected void matched(Graph graph, Matcher m) {
			graph.setAttribute("ui.stylesheet", m.group(1));
		}
	}

	public static class SetClassCommand extends RegexCommand {
		public SetClassCommand() {
			super(Pattern.compile("SetClass\\((.*?),(.*?)\\)"));
		}

		@Override
		protected void matched(Graph graph, Matcher m) {
			String idOfNode = m.group(1);
			String clazz = m.group(2);
			Node n = graph.getNode(idOfNode);
			if (n == null) {
				System.out.println("could not find " + idOfNode
						+ " when setting class " + clazz);
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
		protected void matched(Graph graph, Matcher m) {
			String idOfNode1 = m.group(1);
			Node n1 = graph.getNode(idOfNode1);
			String idOfNode2 = m.group(2);
			Node n2 = graph.getNode(idOfNode2);
			if (n1 == null) {
				System.out.println("could not find " + idOfNode1
						+ " when creating edge");
				return;
			}
			if (n2 == null) {
				System.out.println("could not find " + idOfNode2
						+ " when creating edge");
				return;
			}
			String edgeId = idOfNode1 + "->" + idOfNode2;
			if (graph.getEdge(edgeId) != null) {
				System.out.println("edge already registered '" + edgeId + "'");
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
		public void matched(Graph graph, Matcher m) {
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
				System.out.println("no command found for command: '" + s + "'");
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
				System.out.println("Got from client: " + s);
				commands.execute(fGraph, s);
				s = r.readLine();
			}
		}
	}

	private DefaultGraph fGraph;
	private ServerSocket fServerSocket;
  private ThreadProxyPipe fPipe;

	public GraphStreamServer() throws Exception {
		fGraph = new SingleGraph("single grapgh");
		fPipe = new ThreadProxyPipe(fGraph);
	}
	
	public ThreadProxyPipe getPipe() {
    return fPipe;
  }

	public void start() throws Exception {
		fServerSocket = new ServerSocket(31217);
		new Thread() {
			public void run() {
				try {
					while (true) {
						Socket clientSocket = fServerSocket.accept();
						new GraphStreamServerClient(
								clientSocket.getInputStream(),
								clientSocket.getOutputStream());
					}
				} catch (Exception e) {
					System.out.println("finishing server");
				}
			}
		}.start();
	}

	public void pleaseStop() throws Exception {
		fServerSocket.close();
	}

	public Graph getGraph() {
		return fGraph;
	}

}