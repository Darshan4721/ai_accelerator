package uvm_report_pkg;
    // Standardized Segmented Box Reporting for SysMAC Hybrid
    
    int total_tests_number = 0;
    int failed_tests_number = 0;

    // Task: Print a banner for major sections
    task automatic print_banner(string title);
        $display("\n==================================================");
        $display("  %s", title);
        $display("==================================================");
    endtask

    // Task: Print an individual test box (The user's Segmented Box Format)
    task automatic print_test_box(string name, bit error_flag);
        total_tests_number = total_tests_number + 1;
        if (error_flag) failed_tests_number = failed_tests_number + 1;

        $display("==================================================");
        $display("             %s", name); // Centered Title
        $display("--------------------------------------------------");
        
        if (error_flag) begin
            $display(" ERRORS LOGGED: Yes (See simulator output above)");
        end else begin
            $display(" ERRORS LOGGED: None");
        end
        
        $display("--------------------------------------------------");
        
        if (error_flag) begin 
            $display(" SUMMARY : FAIL");
        end else begin
            $display(" SUMMARY : PASS");
        end
        
        $display("==================================================\n");
    endtask

    // Task: Print the final summary report
    task automatic print_final_report();
        $display("\n\n");
        print_banner("FINAL TEST SUMMARY");
        
        $display(" Total Test Cases  : %0d", total_tests_number);
        $display(" Failed Test Cases : %0d", failed_tests_number);
        $display(" Passed Test Cases : %0d", total_tests_number - failed_tests_number);

        if (failed_tests_number == 0 && total_tests_number > 0)
            $display("\n OVERALL RESULT : PASS\n");
        else
            $display("\n OVERALL RESULT : FAIL\n");
            
        $display("\n\n");
    endtask

    // Reset counters for back-to-back testing
    function void reset_counters();
        total_tests_number = 0;
        failed_tests_number = 0;
    endfunction

endpackage
