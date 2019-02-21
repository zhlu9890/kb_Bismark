
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
 * <p>Original spec-file type: extractorParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "alignment_ref",
    "assembly_or_genome_ref",
    "output_workspace"
})
public class ExtractorParams {

    @JsonProperty("alignment_ref")
    private String alignmentRef;
    @JsonProperty("assembly_or_genome_ref")
    private String assemblyOrGenomeRef;
    @JsonProperty("output_workspace")
    private String outputWorkspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("alignment_ref")
    public String getAlignmentRef() {
        return alignmentRef;
    }

    @JsonProperty("alignment_ref")
    public void setAlignmentRef(String alignmentRef) {
        this.alignmentRef = alignmentRef;
    }

    public ExtractorParams withAlignmentRef(String alignmentRef) {
        this.alignmentRef = alignmentRef;
        return this;
    }

    @JsonProperty("assembly_or_genome_ref")
    public String getAssemblyOrGenomeRef() {
        return assemblyOrGenomeRef;
    }

    @JsonProperty("assembly_or_genome_ref")
    public void setAssemblyOrGenomeRef(String assemblyOrGenomeRef) {
        this.assemblyOrGenomeRef = assemblyOrGenomeRef;
    }

    public ExtractorParams withAssemblyOrGenomeRef(String assemblyOrGenomeRef) {
        this.assemblyOrGenomeRef = assemblyOrGenomeRef;
        return this;
    }

    @JsonProperty("output_workspace")
    public String getOutputWorkspace() {
        return outputWorkspace;
    }

    @JsonProperty("output_workspace")
    public void setOutputWorkspace(String outputWorkspace) {
        this.outputWorkspace = outputWorkspace;
    }

    public ExtractorParams withOutputWorkspace(String outputWorkspace) {
        this.outputWorkspace = outputWorkspace;
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
        return ((((((((("ExtractorParams"+" [alignmentRef=")+ alignmentRef)+", assemblyOrGenomeRef=")+ assemblyOrGenomeRef)+", outputWorkspace=")+ outputWorkspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
