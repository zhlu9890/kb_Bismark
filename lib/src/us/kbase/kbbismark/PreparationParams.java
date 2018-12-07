
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
 * <p>Original spec-file type: preparationParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "assembly_or_genome_ref",
    "output_dir",
    "ws_for_cache"
})
public class PreparationParams {

    @JsonProperty("assembly_or_genome_ref")
    private String assemblyOrGenomeRef;
    @JsonProperty("output_dir")
    private String outputDir;
    @JsonProperty("ws_for_cache")
    private String wsForCache;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("assembly_or_genome_ref")
    public String getAssemblyOrGenomeRef() {
        return assemblyOrGenomeRef;
    }

    @JsonProperty("assembly_or_genome_ref")
    public void setAssemblyOrGenomeRef(String assemblyOrGenomeRef) {
        this.assemblyOrGenomeRef = assemblyOrGenomeRef;
    }

    public PreparationParams withAssemblyOrGenomeRef(String assemblyOrGenomeRef) {
        this.assemblyOrGenomeRef = assemblyOrGenomeRef;
        return this;
    }

    @JsonProperty("output_dir")
    public String getOutputDir() {
        return outputDir;
    }

    @JsonProperty("output_dir")
    public void setOutputDir(String outputDir) {
        this.outputDir = outputDir;
    }

    public PreparationParams withOutputDir(String outputDir) {
        this.outputDir = outputDir;
        return this;
    }

    @JsonProperty("ws_for_cache")
    public String getWsForCache() {
        return wsForCache;
    }

    @JsonProperty("ws_for_cache")
    public void setWsForCache(String wsForCache) {
        this.wsForCache = wsForCache;
    }

    public PreparationParams withWsForCache(String wsForCache) {
        this.wsForCache = wsForCache;
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
        return ((((((((("PreparationParams"+" [assemblyOrGenomeRef=")+ assemblyOrGenomeRef)+", outputDir=")+ outputDir)+", wsForCache=")+ wsForCache)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
