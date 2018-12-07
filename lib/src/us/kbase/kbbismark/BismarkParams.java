
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
 * <p>Original spec-file type: bismarkParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "input_ref",
    "assembly_or_genome_ref",
    "lib_type",
    "mismatch",
    "length",
    "qual",
    "minins",
    "maxins"
})
public class BismarkParams {

    @JsonProperty("input_ref")
    private String inputRef;
    @JsonProperty("assembly_or_genome_ref")
    private String assemblyOrGenomeRef;
    @JsonProperty("lib_type")
    private String libType;
    @JsonProperty("mismatch")
    private Long mismatch;
    @JsonProperty("length")
    private Long length;
    @JsonProperty("qual")
    private String qual;
    @JsonProperty("minins")
    private Long minins;
    @JsonProperty("maxins")
    private Long maxins;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("input_ref")
    public String getInputRef() {
        return inputRef;
    }

    @JsonProperty("input_ref")
    public void setInputRef(String inputRef) {
        this.inputRef = inputRef;
    }

    public BismarkParams withInputRef(String inputRef) {
        this.inputRef = inputRef;
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

    public BismarkParams withAssemblyOrGenomeRef(String assemblyOrGenomeRef) {
        this.assemblyOrGenomeRef = assemblyOrGenomeRef;
        return this;
    }

    @JsonProperty("lib_type")
    public String getLibType() {
        return libType;
    }

    @JsonProperty("lib_type")
    public void setLibType(String libType) {
        this.libType = libType;
    }

    public BismarkParams withLibType(String libType) {
        this.libType = libType;
        return this;
    }

    @JsonProperty("mismatch")
    public Long getMismatch() {
        return mismatch;
    }

    @JsonProperty("mismatch")
    public void setMismatch(Long mismatch) {
        this.mismatch = mismatch;
    }

    public BismarkParams withMismatch(Long mismatch) {
        this.mismatch = mismatch;
        return this;
    }

    @JsonProperty("length")
    public Long getLength() {
        return length;
    }

    @JsonProperty("length")
    public void setLength(Long length) {
        this.length = length;
    }

    public BismarkParams withLength(Long length) {
        this.length = length;
        return this;
    }

    @JsonProperty("qual")
    public String getQual() {
        return qual;
    }

    @JsonProperty("qual")
    public void setQual(String qual) {
        this.qual = qual;
    }

    public BismarkParams withQual(String qual) {
        this.qual = qual;
        return this;
    }

    @JsonProperty("minins")
    public Long getMinins() {
        return minins;
    }

    @JsonProperty("minins")
    public void setMinins(Long minins) {
        this.minins = minins;
    }

    public BismarkParams withMinins(Long minins) {
        this.minins = minins;
        return this;
    }

    @JsonProperty("maxins")
    public Long getMaxins() {
        return maxins;
    }

    @JsonProperty("maxins")
    public void setMaxins(Long maxins) {
        this.maxins = maxins;
    }

    public BismarkParams withMaxins(Long maxins) {
        this.maxins = maxins;
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
        return ((((((((((((((((((("BismarkParams"+" [inputRef=")+ inputRef)+", assemblyOrGenomeRef=")+ assemblyOrGenomeRef)+", libType=")+ libType)+", mismatch=")+ mismatch)+", length=")+ length)+", qual=")+ qual)+", minins=")+ minins)+", maxins=")+ maxins)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
