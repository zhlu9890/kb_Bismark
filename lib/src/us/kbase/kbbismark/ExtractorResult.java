
package us.kbase.kbbismark;

import java.util.HashMap;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: extractorResult</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "result_directory",
    "bedgraph_ref",
    "report_name",
    "report_ref"
})
public class ExtractorResult {

    @JsonProperty("result_directory")
    private String resultDirectory;
    @JsonProperty("bedgraph_ref")
    private String bedgraphRef;
    @JsonProperty("report_name")
    private String reportName;
    @JsonProperty("report_ref")
    private String reportRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("result_directory")
    public String getResultDirectory() {
        return resultDirectory;
    }

    @JsonProperty("result_directory")
    public void setResultDirectory(String resultDirectory) {
        this.resultDirectory = resultDirectory;
    }

    public ExtractorResult withResultDirectory(String resultDirectory) {
        this.resultDirectory = resultDirectory;
        return this;
    }

    @JsonProperty("bedgraph_ref")
    public String getBedgraphRef() {
        return bedgraphRef;
    }

    @JsonProperty("bedgraph_ref")
    public void setBedgraphRef(String bedgraphRef) {
        this.bedgraphRef = bedgraphRef;
    }

    public ExtractorResult withBedgraphRef(String bedgraphRef) {
        this.bedgraphRef = bedgraphRef;
        return this;
    }

    @JsonProperty("report_name")
    public String getReportName() {
        return reportName;
    }

    @JsonProperty("report_name")
    public void setReportName(String reportName) {
        this.reportName = reportName;
    }

    public ExtractorResult withReportName(String reportName) {
        this.reportName = reportName;
        return this;
    }

    @JsonProperty("report_ref")
    public String getReportRef() {
        return reportRef;
    }

    @JsonProperty("report_ref")
    public void setReportRef(String reportRef) {
        this.reportRef = reportRef;
    }

    public ExtractorResult withReportRef(String reportRef) {
        this.reportRef = reportRef;
        return this;
    }

    @JsonAnyGetter
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public String toString() {
        return ((((((((((("ExtractorResult"+" [resultDirectory=")+ resultDirectory)+", bedgraphRef=")+ bedgraphRef)+", reportName=")+ reportName)+", reportRef=")+ reportRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
