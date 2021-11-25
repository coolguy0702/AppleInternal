tailspin holds onto 20-30 seconds of historical spindump and Ariadne data, from before the sysdiagnose invocation.

Visualization of tailspin information

    For raw trace data: `ktrace trace -R <path_to_tailspin_trace_file>`

    For spindump output: `spindump -i <path_to_tailspin_trace_file>`. For full symbols, you can use the -dsymForUUID flag with spindump

    For fs_usage output: `fs_usage -w -R <path_to_tailspin_file>`

    For Ariadne visualization: Please use the Ariadne from Tigris15A221 and Lobo17A202 onwards to open the tailspin file. You can also download the latest Ariadne from https://toolsweb.apple.com/apps/ariadne

How do I file a bug against tailspin?
<rdar://component/595220> tailspin | all
<rdar://component/635501> Ariadne | X

If tailspin information has helped you diagnose problems, please also tag the bug with the `Found by tailspin` radar keyword so that the macOS and iOS Performance team can evaluate tailspin's usefulness.

More information:
    Please refer to the tailspin man page for more details.
    tailspin help group: tailspin-help@group.apple.com.

