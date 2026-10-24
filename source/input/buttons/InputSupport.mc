// No touch delegate, bell or alternate-view controls in button-only binaries.
module InputSupport {
    const ENABLED = false;
    function initialView(field) { return [field]; }
}
