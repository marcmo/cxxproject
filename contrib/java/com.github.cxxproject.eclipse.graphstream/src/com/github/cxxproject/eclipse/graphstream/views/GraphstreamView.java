package com.github.cxxproject.eclipse.graphstream.views;

import org.eclipse.jface.action.Action;
import org.eclipse.jface.action.IToolBarManager;
import org.eclipse.jface.resource.ImageDescriptor;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
import org.eclipse.ui.IActionBars;
import org.eclipse.ui.part.ViewPart;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.ui.graphicGraph.GraphicGraph;
import org.graphstream.ui.layout.Layout;

import com.github.cxxproject.eclipse.graphstream.Activator;

public class GraphstreamView extends ViewPart {

  public static final String ID = "com.github.cxxproject.eclipse.graphstream.views.GraphstreamView";

  private static final int DELAY = 60;

  Canvas fCanvas;

  private GraphStreamServer fServer;

  private GraphicGraph fGraphicGraph;
  private ZoomInfo fZoomInfo = new ZoomInfo();

  private SingleGraph fGraph;

  private Layout fLayout;

  private Action fStartServer;

  private Action fStopServer;

  protected boolean running;

  public void createPartControl(Composite parent) {
    try {
      fCanvas = new Canvas(parent, SWT.NONE);
      fServer = new GraphStreamServer();
      IActionBars bars = getViewSite().getActionBars();
      addToActionBar(bars.getToolBarManager());

      createGraph();
      fCanvas.addPaintListener(new GraphPaintListener(fGraphicGraph, fZoomInfo));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private void createGraph() {
    // create graph
    // final Graph graph = fServer.getGraph();
    fGraph = new SingleGraph("1234");
    fServer.getPipe().addSink(fGraph);

    fGraphicGraph = new GraphicGraph("graphical graph");
    fGraph.addSink(fGraphicGraph);

    fLayout = new GoodLayout();
    fLayout.setStabilizationLimit(0.8);
    fGraph.addSink(fLayout);
    fLayout.addAttributeSink(fGraph);
  }

  private void triggerRepaint() {
    System.out.println("1");
    running = true;
    runRunnable(new Runnable() {
      @Override
      public void run() {
        if (running) {
          System.out.print(".");
          fServer.getPipe().pump();
          double stabilization = fLayout.getStabilization();
          if (stabilization < 0.9) {
            fLayout.compute();
          }
          display(fGraphicGraph);
          runRunnable(this);
        }
      }

      private void display(GraphicGraph g) {
        if (!fCanvas.isDisposed()) {
          fCanvas.redraw();
        }
      }
    });
    System.out.println("2");
  }

  private void setEnabled(boolean a, boolean b) {
    fStartServer.setEnabled(a);
    fStopServer.setEnabled(b);
  }

  private void addToActionBar(IToolBarManager iToolBarManager) {
    fStartServer = new Action("Start Server", icon(Activator.CONNECT)) {
      @Override
      public void run() {
        try {
          System.out.print("Starting server...");
          fServer.start();
           triggerRepaint();
          System.out.println();
          System.out.println("setting icons");
          GraphstreamView.this.setEnabled(false, true);
          System.out.println("ok");
        } catch (Exception e) {
          System.out.println("not ok");
          e.printStackTrace();
        }
      }

    };
    fStopServer = new Action("Stop Server", icon(Activator.DISCONNECT)) {
      @Override
      public void run() {
        try {
          System.out.print("Stopping server...");
          stopServer();
          System.out.println("ok");
        } catch (Exception e) {
          System.out.println("not ok");
          e.printStackTrace();
        }
        fStartServer.setEnabled(true);
        GraphstreamView.this.setEnabled(true, false);
      }
    };
    setEnabled(true, false);
    iToolBarManager.add(fStartServer);
    iToolBarManager.add(fStopServer);
    iToolBarManager.add(new Action("ZoomIn", icon(Activator.ZOOM_IN)) {
      @Override
      public void run() {
        fZoomInfo.incZoom();
      }
    });
    iToolBarManager.add(new Action("ZoomOut", icon(Activator.ZOOM_OUT)) {
      @Override
      public void run() {
        fZoomInfo.decZoom();
      }
    });
  }

  private ImageDescriptor icon(String zoomIn) {
    return Activator.getDefault().getImageRegistry().getDescriptor(zoomIn);
  }

  private void runRunnable(Runnable runnable) {
    Display.getCurrent().timerExec(DELAY, runnable);
  }

  public void setFocus() {
    fCanvas.setFocus();
  }

  @Override
  public void dispose() {
    try {
      stopServer();
    } catch (Exception e) {
      e.printStackTrace();
    }
    super.dispose();
  }

  private void stopServer() throws Exception {
    try {
      fServer.pleaseStop();
      running = false;
    } finally {
      running = false;
    }
  }
}
