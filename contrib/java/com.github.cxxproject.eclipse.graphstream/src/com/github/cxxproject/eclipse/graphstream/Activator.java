package com.github.cxxproject.eclipse.graphstream;

import org.eclipse.jface.resource.ImageDescriptor;
import org.eclipse.jface.resource.ImageRegistry;
import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.osgi.framework.BundleContext;

/**
 * The activator class controls the plug-in life cycle
 */
public class Activator extends AbstractUIPlugin {

	// The plug-in ID
	public static final String PLUGIN_ID = "com.github.cxxproject.eclipse.graphstream"; //$NON-NLS-1$

  public static final String ZOOM_IN = "zoom_in";
  public static final String ZOOM_OUT = "zoom_out";
  public static final String CONNECT = "connect";
  public static final String DISCONNECT = "disconnect";

	// The shared instance
	private static Activator plugin;
	
	@Override
	protected void initializeImageRegistry(ImageRegistry reg) {
	  super.initializeImageRegistry(reg);
	  String basePath = "icons/";
    reg.put(ZOOM_IN, imageDescriptorFromPlugin(PLUGIN_ID, basePath + "zoom_in.png"));
    reg.put(ZOOM_OUT, imageDescriptorFromPlugin(PLUGIN_ID, basePath + "zoom_out.png"));
    reg.put(CONNECT, imageDescriptorFromPlugin(PLUGIN_ID, basePath + "connect.png"));
    reg.put(DISCONNECT, imageDescriptorFromPlugin(PLUGIN_ID, basePath + "disconnect.png"));
	}
	/**
	 * The constructor
	 */
	public Activator() {
	}

	/*
	 * (non-Javadoc)
	 * @see org.eclipse.ui.plugin.AbstractUIPlugin#start(org.osgi.framework.BundleContext)
	 */
	public void start(BundleContext context) throws Exception {
		super.start(context);
		plugin = this;
	}

	/*
	 * (non-Javadoc)
	 * @see org.eclipse.ui.plugin.AbstractUIPlugin#stop(org.osgi.framework.BundleContext)
	 */
	public void stop(BundleContext context) throws Exception {
		plugin = null;
		super.stop(context);
	}

	/**
	 * Returns the shared instance
	 *
	 * @return the shared instance
	 */
	public static Activator getDefault() {
		return plugin;
	}

	/**
	 * Returns an image descriptor for the image file at the given
	 * plug-in relative path
	 *
	 * @param path the path
	 * @return the image descriptor
	 */
	public static ImageDescriptor getImageDescriptor(String path) {
		return imageDescriptorFromPlugin(PLUGIN_ID, path);
	}
}
