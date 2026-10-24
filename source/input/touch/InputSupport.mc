// Touch input is compiled only for touch-capable devices.
module InputSupport {
    const ENABLED = true;
    function initialView(field) { return [field, new FastRiderInputDelegate(field)]; }
}
