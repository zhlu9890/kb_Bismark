
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
 * <p>Original spec-file type: preparationResult</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "output_dir",
    "from_cache",
    "pushed_to_cache"
})
public class PreparationResult {

    @JsonProperty("output_dir")
    private String outputDir;
    @JsonProperty("from_cache")
    private Long fromCache;
    @JsonProperty("pushed_to_cache")
    private Long pushedToCache;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("output_dir")
    public String getOutputDir() {
        return outputDir;
    }

    @JsonProperty("output_dir")
    public void setOutputDir(String outputDir) {
        this.outputDir = outputDir;
    }

    public PreparationResult withOutputDir(String outputDir) {
        this.outputDir = outputDir;
        return this;
    }

    @JsonProperty("from_cache")
    public Long getFromCache() {
        return fromCache;
    }

    @JsonProperty("from_cache")
    public void setFromCache(Long fromCache) {
        this.fromCache = fromCache;
    }

    public PreparationResult withFromCache(Long fromCache) {
        this.fromCache = fromCache;
        return this;
    }

    @JsonProperty("pushed_to_cache")
    public Long getPushedToCache() {
        return pushedToCache;
    }

    @JsonProperty("pushed_to_cache")
    public void setPushedToCache(Long pushedToCache) {
        this.pushedToCache = pushedToCache;
    }

    public PreparationResult withPushedToCache(Long pushedToCache) {
        this.pushedToCache = pushedToCache;
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
        return ((((((((("PreparationResult"+" [outputDir=")+ outputDir)+", fromCache=")+ fromCache)+", pushedToCache=")+ pushedToCache)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
