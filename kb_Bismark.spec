/*
A KBase module: kb_Bismark
*/

module kb_Bismark {
    /* A boolean - 0 for false, 1 for true.
        @range (0, 1)
    */
    typedef int boolean;

    typedef structure {
      string assembly_or_genome_ref;
      string output_dir;
      string ws_for_cache;
    } preparationParams;

    typedef structure {
      string output_dir;
      boolean from_cache;
      boolean pushed_to_cache;
    } preparationResult;

    typedef structure {
      string input_ref;
      string assembly_or_genome_ref;

      string output_workspace;

      string lib_type;
      int mismatch;
      int length;
      string qual;
      int minins;
      int maxins;
    } bismarkParams;

    typedef structure {
      string alignment_ref;
      string report_name;
      string report_ref;
    } bismarkResult;

    typedef structure {
      string input_ref;
      string assembly_or_genome_ref;

      string output_workspace;

      string lib_type;
      int mismatch;
      int length;
      string qual;
      int minins;
      int maxins;
    } bismarkAppParams;

    typedef structure {
      string alignment_ref;
      string report_name;
      string report_ref;
    } bismarkAppResult;

    typedef structure {
        string alignment_ref;
    } extractorParams;

    typedef structure {
        string report_ref;
    } extractorResult;

    typedef structure {
      string command_name;
      list <string> options;
    } RunBismarkCLIParams;

    funcdef genome_preparation (preparationParams params)
      returns (preparationResult result) authentication required;

    funcdef bismark (bismarkParams params)
      returns (bismarkResult result) authentication required;

    funcdef methylation_extractor (extractorParams params)
      returns (extractorResult result) authentication required;

    funcdef bismark_app (bismarkAppParams params)
      returns (bismarkAppResult result) authentication required;

    funcdef run_bismark_cli(RunBismarkCLIParams params)
      returns () authentication required;

};
