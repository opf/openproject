import { describe, it, expect, vi, beforeAll, afterAll } from "vitest";
import { render } from "vitest-browser-react";
import { page, userEvent } from "vitest/browser";
import { WorkPackageElement } from "../../../../lib/elements/workPackageElement";
import { worker } from "../../../mocks/browser";
import { linkToWorkPackage } from "../../../../lib/services/openProjectApi";

const mockWorkPackage = {
  id: 123,
  subject: "Test WP",
  _links: {
    self: { href: "/wp/123" },
    type: { title: "Feature", href: "/types/1" },
    status: { title: "Open", href: "/statuses/1" },
    assignee: { title: "John Doe", href: "/users/1" },
  },
};

beforeAll(async () => {
  await worker.start();
});

afterAll(() => {
  worker.stop();
});

describe("WorkPackageElement Integration + MSW - #71898", () => {
  it("opens WP in new tab without redirecting current tab", async () => {
    // Mock window.open
    const openSpy = vi.spyOn(window, "open").mockImplementation((url) => {
      // return a simple object to simulate a new tab
      return { location: { href: url }, closed: false } as unknown as Window;
    });

    render(<WorkPackageElement workPackage={mockWorkPackage} linkTitle={true} />);

    const link = page.getByText("Test WP");

    await userEvent.click(link);

    // Verify that window.open was called with the correct URL
    expect(openSpy).toHaveBeenCalledOnce();
    expect(openSpy).toHaveBeenCalledWith(
      linkToWorkPackage(mockWorkPackage.id),
      "_blank",
      "noopener,noreferrer"
    );

    // Check that the current tab is not redirected
    await expect.element(page.getByText("Test WP")).toBeInTheDocument();
    await expect.element(page.getByText("#123")).toBeInTheDocument();
    await expect.element(page.getByText("Feature")).toBeInTheDocument();
    await expect.element(page.getByText("Open")).toBeInTheDocument();

    openSpy.mockRestore();
  });
});