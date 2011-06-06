package com.github.cxxproject.eclipse.graphstream.views;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.ActionEvent;

import javax.swing.AbstractAction;
import javax.swing.Box;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JSlider;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

import org.graphstream.ui.layout.Layout;
import org.graphstream.ui.swingViewer.View;
import org.graphstream.ui.swingViewer.Viewer;

public class SwingServer {
	@SuppressWarnings("serial")
  public SwingServer(GraphStreamServer server) throws Exception {
	  server.start();
		final Viewer v = new Viewer(server.getGraph(),
				Viewer.ThreadingModel.GRAPH_IN_ANOTHER_THREAD);
		JFrame root = new JFrame("GraphStream View");
		root.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		final View view = v.addDefaultView(false);
		view.setMinimumSize(new Dimension(300, 300));
		view.setPreferredSize(new Dimension(300, 300));

		final Layout l = new GoodLayout();
		l.setStabilizationLimit(0.9);
		v.enableAutoLayout(l);

		root.getContentPane().add(view, BorderLayout.CENTER);

		Box controls = Box.createHorizontalBox();
		final JSlider zoomSlider = new JSlider(1, 200, 100);
		zoomSlider.addChangeListener(new ChangeListener() {
			@Override
			public void stateChanged(ChangeEvent changeEvent) {
				int i = zoomSlider.getValue();
				view.setViewPercent(100.0 / i);
			}
		});
		controls.add(zoomSlider);
		controls.add(new JButton(new AbstractAction("one step") {
			@Override
			public void actionPerformed(ActionEvent actionEvent) {
				System.out.println("l.getStabilization() = "
						+ l.getStabilization());
				l.compute();
			}
		}));
		controls.add(new JButton(new AbstractAction("shake") {
			@Override
			public void actionPerformed(ActionEvent actionEvent) {
				System.out.println("l.getStabilization() = "
						+ l.getStabilization());
				l.shake();
			}
		}));
		root.getContentPane().add(controls, BorderLayout.SOUTH);
		root.pack();
		root.setVisible(true);

	}

	public static void main(String[] args) throws Exception {
		GraphStreamServer server = new GraphStreamServer();
		new SwingServer(server);
	}
}
