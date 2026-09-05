# frozen_string_literal: true

# Spike: real HTML5 drag via CDP drag interception.
module CdpDrag
  module_function

  def ferrum_page
    Capybara.current_session.driver.browser.page
  end

  def point(element, edge: nil)
    rect = element.rect
    offset = [6, rect["height"] / 4].min
    y =
      case edge
      when :top then rect["y"] + offset
      when :bottom then rect["y"] + rect["height"] - offset
      else rect["y"] + (rect["height"] / 2)
      end

    [(rect["x"] + (rect["width"] / 2)).round, y.round]
  end

  def mouse_event(fpage, type, pos_x, pos_y, button: "left", buttons: 1, click_count: 0)
    params = { type:, x: pos_x, y: pos_y, button:, buttons: }
    params[:clickCount] = click_count if click_count.positive?
    fpage.command("Input.dispatchMouseEvent", **params)
  end

  def drag(source:, target:, edge: nil)
    fpage = ferrum_page
    intercepted = Concurrent::AtomicReference.new(nil)
    subscription = fpage.on("Input.dragIntercepted") { |params, _i, _t| intercepted.set(params["data"]) }
    fpage.command("Input.setInterceptDrags", enabled: true)

    sx, sy = point(source)
    tx, ty = point(target, edge:)

    mouse_event(fpage, "mouseMoved", sx, sy, button: "none", buttons: 0)
    mouse_event(fpage, "mousePressed", sx, sy, click_count: 1)
    # Chrome only starts a drag when the move carries `button`, not just the
    # `buttons` bitmask that Ferrum::Mouse#move sends.
    5.times { |i| mouse_event(fpage, "mouseMoved", sx, sy + ((i + 1) * 6)) }

    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    sleep 0.05 while intercepted.get.nil? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
    data = intercepted.get
    raise "Chrome never intercepted a drag (no Input.dragIntercepted)" if data.nil?

    %w[dragEnter dragOver dragOver drop].each do |type|
      fpage.command("Input.dispatchDragEvent", type:, x: tx, y: ty, data:)
    end

    mouse_event(fpage, "mouseReleased", tx, ty, buttons: 0, click_count: 1)
    # Pragmatic clears its honey-pot overlay on the next pointer move.
    mouse_event(fpage, "mouseMoved", tx, ty + 1, button: "none", buttons: 0)
  ensure
    begin
      fpage.command("Input.setInterceptDrags", enabled: false)
    rescue StandardError
      nil
    end
    fpage.off("Input.dragIntercepted", subscription) if subscription
  end
end
