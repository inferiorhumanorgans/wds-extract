var panZoomControl;

function resizeHandler(ignoreFit) {
  if (typeof(panZoomControl) != "undefined") {
    panZoomControl.destroy();
    delete panZoomControl;
  }

  panZoomControl = svgPanZoom('embed', {
    controlIconsEnabled: true,
    zoomScaleSensitivity: 0.095,
    customEventsHandler: eventsHandler,
    maxZoom: 100
  });
  panZoomControl.updateBBox();
  panZoomControl.resize();
}

function loadjscssfile(filename, filetype, callback) {
  if (filetype == "js") {
    // If filename is a external JavaScript file
    var fileref=document.createElement('script');

    if (typeof(callback) != "undefined") {
      fileref.onload = callback;
    }

    fileref.setAttribute("type","text/javascript");
    fileref.setAttribute("src", filename);
  } else if (filetype == "css") {
    // If filename is an external CSS file
    var fileref=document.createElement("link");
    fileref.setAttribute("rel", "stylesheet");
    fileref.setAttribute("type", "text/css");
    fileref.setAttribute("href", filename);
  }

  if (typeof(fileref) != "undefined") {
    document.getElementsByTagName("head")[0].appendChild(fileref);
  }
}

function showModel() {
};

// This is actually our onload handler...
function showButton() {
  // Point photos at the proper directory
  $('.graphic img').each(function(index, e) {
    var element= $(e);
    var imgSrc = element.attr('src');
    if (imgSrc.startsWith('../../zi_images')) {
      element.attr('src', imgSrc.replace('../../zi_images', '../zi_images'));
    }
  });

  var svg = document.getElementsByTagName('embed')[0].getSVGDocument();;
  svg.onclick = function(ev) {
    if (ev.target.tagName.toLowerCase() == 'a') {
      var x = (ev.target.href.baseVal);
      x.replace('javascript:', '');
      eval(x); // Gross
      return false;
    }
  }

  resizeHandler(true);
  $(window).resize(resizeHandler);
};

function hideButton() {
};

function locateTree(component) {
  var obj;
  if (window.parent != window) {
    window.parent.locateTree(component);
    return;
  }
}

// view-source:http://ariutta.github.io/svg-pan-zoom/demo/mobile.html
var eventsHandler;

var hammerInit = function(options) {
  var instance = options.instance,
      initialScale = 1,
      pannedX = 0,
      pannedY = 0;

  // Init Hammer
  // Listen only for pointer and touch events
  this.hammer = Hammer(options.svgElement, {
    inputClass: Hammer.SUPPORT_POINTER_EVENTS ? Hammer.PointerEventInput : Hammer.TouchInput
  })

  // Enable pinch
  this.hammer.get('pinch').set({enable: true});

  // Handle double tap
  this.hammer.on('doubletap', function(ev) {
    instance.zoomIn()
  });

  // Handle pan
  this.hammer.on('panstart panmove', function(ev) {
    // On pan start reset panned variables
    if (ev.type === 'panstart') {
      pannedX = 0;
      pannedY = 0;
    }

    // Pan only the difference
    instance.panBy({x: ev.deltaX - pannedX, y: ev.deltaY - pannedY});
    pannedX = ev.deltaX;
    pannedY = ev.deltaY;
  });

  // Handle pinch
  this.hammer.on('pinchstart pinchmove', function(ev) {
    // On pinch start remember initial zoom
    if (ev.type === 'pinchstart') {
      initialScale = instance.getZoom();
      instance.zoom(initialScale * ev.scale);
    }

    instance.zoom(initialScale * ev.scale);
  });

  // Prevent moving the page on some devices when panning over SVG
  options.svgElement.addEventListener('touchmove', function(e){ e.preventDefault(); });
};

var hammerDestroy = function() {
  this.hammer.destroy();
};

eventsHandler = {
  haltEventListeners: ['touchstart', 'touchend', 'touchmove', 'touchleave', 'touchcancel'],
  init: hammerInit,
  destroy: hammerDestroy
}

loadjscssfile("https://code.jquery.com/jquery-2.2.3.min.js", "js");
loadjscssfile("/scripts/hammer.min.js", "js");
loadjscssfile("/scripts/svg-pan-zoom.min.js", "js");
