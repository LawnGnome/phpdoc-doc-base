<?xml version="1.0" encoding="iso-8859-1"?>
<!-- 

  HOWTO specific stylesheet based on Docbook XSL 1.66.1

  $Id: howto.xsl,v 1.1 2004-10-01 14:23:21 techtonik Exp $

-->
<!-- 
  Sometimes it is more efficient to have styles and other info in one file
  What is done with 1.66.1 XSL stylesheets:
  - output directory for howto is 'howto/html'
  - xsltproc chunks quietly using division's ids as filenames
  - verbatim parts (like programlisting) are shaded and newlines from start and in the end 
    are stripped
  - chunk default.css stylesheet
  - TOCs are generated only for book, part, chapter and preface.2-level Book ToC and 1-level Part Toc
  - TOC labels not included in href
  - div class="p" is default <para> container to produce valid and customizable html
  - do not generate title for abstract
  - nav.header is not included on the first page
  - first line of nav.header always document title and second line indicates current chapter and 
    only available if current page is not title page for division
  - nav.footer and title do not include division info like chapter numbers
  - exchanged placement for UP and HOME links in footer
  - correct legalnotice chunking with navigation contents
  - nice look for names of authors and editors
  - notes|important|caution|tip inline, warnings in table
  
  Probable enchancements:
  - include external default.css file into generation process instead of inline CSS CDATA
  - if not chunking - include stylesheet as <head> <style> element

  Commited by techtonik
  Proposals and questions can be sent at php.net
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href="./db/html/chunk.xsl"/>




<!-- ==================================================================== -->
<!-- Customizations of standard HTML stylesheet parameters -->
 
  <xsl:param name="base.dir" select="'howto/html/'"/>

  <!-- These should be migrated to common customizations -->
  <xsl:param name="use.id.as.filename" select="1"/>
  <xsl:param name="chunk.quietly" select="1"/>
  <!-- Turn on background shading for program listings and screens -->
  <xsl:param name="shade.verbatim" select="1"/>
 
  <!-- Autogenerated below -->
  <xsl:param name="html.stylesheet" select="'default.css'"/>

  <xsl:param name="html.cleanup" select="1"/>
  <xsl:param name="make.valid.html" select="1"/>




<!-- ==================================================================== -->
<!-- Customizing table of contents -->
  <!-- Generate TOC only for selected sections and supress the ",figure,example,equation" -->
  <!-- (like DSSSL output). ",title" here means "Table of Contents" header -->
  <xsl:param name="generate.toc">
    book      toc,title
    part      toc,title
    chapter   toc,title
    preface   toc
  </xsl:param>
  <xsl:param name="toc.max.depth" select="2"/>
  <xsl:param name="toc.section.depth" select="1"/>

  <!-- Generate numeric labels in section titles -->
  <xsl:param name="section.autolabel" select="1"/>
  <xsl:param name="section.label.includes.component.label" select="1"/>
  <xsl:param name="component.label.includes.part.label" select="0"/>

  <!-- Make the TOC-DEPTHS like in the DSSSL-version  (2-level Book ToC and
       1-level Part Toc) though one more level in Part ToC is more to my 
       liking. Based on autotoc.xsl from DocBook XSL Stylesheets 1.66.1 -->
  <xsl:template match="chapter" mode="toc">
    <xsl:param name="toc-context" select="."/>

    <xsl:choose>
      <xsl:when test="local-name($toc-context) = 'part'">
        <xsl:call-template name="subtoc">
          <xsl:with-param name="toc-context" select="$toc-context"/>
          <xsl:with-param name="nodes" select="foo"/>
          <xsl:with-param name="toc.max.depth" select="1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="subtoc">
          <xsl:with-param name="toc-context" select="$toc-context"/>
          <xsl:with-param name="nodes" select="section|sect1|simplesect|refentry
                                               |glossary|bibliography|index
                                               |bridgehead[$bridgehead.in.toc != 0]"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Make the TOC line like in the DSSSL-version, i.e. label is not included in href -->
  <xsl:template name="toc.line">
    <xsl:param name="toc-context" select="."/>
    <xsl:param name="depth" select="1"/>
    <xsl:param name="depth.from.context" select="8"/>

    <span>
    <xsl:attribute name="class"><xsl:value-of select="local-name(.)"/></xsl:attribute>

    <xsl:variable name="label">
      <xsl:apply-templates select="." mode="label.markup"/>
    </xsl:variable>
    <xsl:copy-of select="$label"/>
    <xsl:if test="$label != ''">
      <xsl:value-of select="$autotoc.label.separator"/>
    </xsl:if>

    <a>
      <xsl:attribute name="href">
        <xsl:call-template name="href.target">
          <xsl:with-param name="context" select="$toc-context"/>
        </xsl:call-template>
      </xsl:attribute>
      
      <xsl:apply-templates select="." mode="titleabbrev.markup"/>
    </a>
    </span>
  </xsl:template>




<!-- ==================================================================== -->
<!-- Strip newlines before and after programlistings. That was a challenge.. -->
  <xsl:template match="programlisting|screen|synopsis">
    <xsl:param name="suppress-numbers" select="'0'"/>
    <xsl:variable name="id">
      <xsl:call-template name="object.id"/>
    </xsl:variable>

    <xsl:call-template name="anchor"/>

    <xsl:variable name="content">
      <pre class="{name(.)}">
      <xsl:variable name="precontent">
        <xsl:choose>
          <xsl:when test="count(*|text()) = count(text()) = 1"><!-- only text() here -->
            <xsl:call-template name="trim_newlines"/>
          </xsl:when>

          <xsl:otherwise>                                      <!-- mixed content - process separately to keep markup tags -->
            <xsl:variable name="nameoffirst" select="local-name((*|text())[position()=1])"/>
            <xsl:if test="$nameoffirst = ''"><!-- 1st node is text() -->
              <xsl:call-template name="trim_newlines">
                <xsl:with-param name="string" select="text()[position()=1]"/>
                <xsl:with-param name="lttrim" select="true()"/>
              </xsl:call-template>
            </xsl:if>
            <xsl:choose>
              <xsl:when test="local-name((*|text())[position()=last()]) != ''"><!-- last node is not text() -->
                <xsl:if test="$nameoffirst = ''"><!-- 1st text() node is already processed -->
                   <xsl:apply-templates select="*|text()[position()!=1]"/>
                </xsl:if>
                <xsl:if test="$nameoffirst != ''"><!-- 1st text() was not processed -->
                   <xsl:apply-templates />
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <xsl:if test="$nameoffirst = ''"><!-- 1st text() node is already processed -->
                   <xsl:apply-templates select="*|text()[position()!=1 and position()!=last()]"/>
                </xsl:if>
                <xsl:if test="$nameoffirst != ''"><!-- 1st text() was not processed -->
                   <xsl:apply-templates select="*|text()[position()!=last()]"/>
                </xsl:if>
                <xsl:call-template name="trim_newlines">
                  <xsl:with-param name="string" select="text()[position()=last()]"/>
                  <xsl:with-param name="rttrim" select="true()"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="$suppress-numbers = '0'
                        and @linenumbering = 'numbered'
                        and $use.extensions != '0'
                        and $linenumbering.extension != '0'">
          <xsl:call-template name="number.rtf.lines">
            <xsl:with-param name="rtf" select="$precontent"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$precontent"/>
        </xsl:otherwise>
      </xsl:choose>
      </pre>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$shade.verbatim != 0">
        <table xsl:use-attribute-sets="shade.verbatim.style">
          <tr>
            <td>
              <xsl:copy-of select="$content"/>
            </td>
          </tr>
        </table>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$content"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="trim_newlines">
    <xsl:param name="string" select="."/>
    <xsl:param name="lttrim" select="false()"/>
    <xsl:param name="rttrim" select="false()"/> <!-- looking for endstring -->

    <xsl:variable name="nl" select="'&#xA;'" />

    <xsl:choose>
      <xsl:when test="normalize-space($string) and contains($string,$nl)"><!-- prevent endless cycle on empty blocks -->
        <xsl:variable name="beforenl" select="substring-before($string,$nl)" />
        <xsl:variable name="afternl" select="substring-after($string,$nl)" />
        <xsl:variable name="nextnl" select="normalize-space(substring-before($afternl,$nl))" />
        <xsl:choose>
          <xsl:when test="not($rttrim) and string-length(normalize-space($beforenl)) = 0">
            <xsl:call-template name="trim_newlines">
              <xsl:with-param name="string" select="$afternl" />
              <xsl:with-param name="lttrim" select="$lttrim" />
              <xsl:with-param name="rttrim" select="$rttrim or $nextnl" />
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="concat($beforenl,$nl)"/>
            <xsl:if test="$lttrim">
              <xsl:copy-of select="$afternl"/>
            </xsl:if>
            <xsl:if test="not($lttrim)">
              <xsl:call-template name="trim_newlines">
                <xsl:with-param name="string" select="$afternl" />
                <xsl:with-param name="rttrim" select="true()" />
              </xsl:call-template>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="normalize-space($string)">
          <xsl:copy-of select="$string"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


<!-- Make <para> enclosed in <div> (to make possible to set margins) CSS -->
<!-- get rid of unwrap.p because <div> allows more freedom for modification -->
  <xsl:template name="paragraph">
    <xsl:param name="class" select="''"/>
    <xsl:param name="content"/>

    <div class="p">
      <xsl:if test="$class != ''">
        <xsl:attribute name="class">
          <xsl:value-of select="$class"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:copy-of select="$content"/>
    </div>

  </xsl:template>




<!-- ==================================================================== -->
<!-- Customizing main pages for divisions -->
<!-- Do not generate title for abstract page (like in DSSSL) -->
<xsl:template match="abstract">
  <div class="{name(.)}">
    <xsl:call-template name="anchor"/>
    <blockquote>
      <xsl:apply-templates/>
    </blockquote>
  </div>
</xsl:template>

<!-- Prefix part title with number -->
<xsl:template match="part/title/text()" mode="titlepage.mode">
  <xsl:number from="book" count="part" format="I. "/>
  <xsl:value-of select="." />
</xsl:template>




<!-- ==================================================================== -->
<!-- Writing default CSS stylesheet -->
<!-- Unsure about this special customization - "default.css" template must be executed only once
     and "/" node in "process.root" mode seems to be working for this purpose, but it is still
     unclear if it is a proper place to do that.
     TODO: If we are not chunking - include stylesheet as <head> <style> element -->
  <xsl:template match="/" mode="process.root"> 
    <xsl:call-template name="default.css"/>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template name="default.css">
     <xsl:variable name="content"><![CDATA[
/* This is default CSS style for XSL generated HTMLs to make them look like from DSSSL output */

/* For <div class="p"> in sections where <p> was replaced by <div> to allow nested block elements */
.p      {margin-top:1em; margin-bottom:1em}
li      {margin-top:1em; margin-bottom:1em}
dt      {margin-top:1em; margin-bottom:1em}

/* Display notes inline */
.note .p {display:inline}

/* For TOC headers look like DSSSL ones - no empty line with TOC elements */
.toc p  {margin-bottom:0}
.toc dl {margin-top:0}
.toc dt {margin:0}

/* Customize programlistings */
pre {margin:1ex}

/* Make literals look like in DSSSL - vars */
.literal {font:oblique 1em serif;}
.parameter {font:italic;}

.filename {font:monospace}

]]>
     </xsl:variable>
     <xsl:call-template name="write.text.chunk">
       <xsl:with-param name="filename" select="concat($base.dir,'default.css')"/>
       <xsl:with-param name="content" select="$content"/>
       <xsl:with-param name="quiet" select="$chunk.quietly"/>
     </xsl:call-template>
  </xsl:template> <!-- -->

  <!-- Supply information for generate.manifest -->
  <xsl:template match="*" mode="enumerate-files">
    <xsl:apply-imports/>
    <xsl:call-template name="make-relative-filename">
      <xsl:with-param name="base.dir">
        <xsl:if test="$manifest.in.base.dir = 0">
          <xsl:value-of select="$base.dir"/>
        </xsl:if>
      </xsl:with-param>
      <xsl:with-param name="base.name" select="'default.css'"/>
    </xsl:call-template>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>




<!-- ==================================================================== -->
<!-- Fix navigation HEADERS and provide mechanizm for correct legalnotice generation -->
<!-- 1. Do not include nav header on the first page -->
<!-- 2. First line of nav.header always should be document title -->
<!-- 3. Second line indicates current chapter and only available if current page is not title -->
<!-- 4. nav.footer and title should not include division info like chapter numbers -->
<!-- 5. Process legalnotice UP link like book element instead of bookinfo (to avoid warnings) -->
<!-- 6. Exchange placement of UP and HOME links in footer -->

<xsl:template name="chunk-element-content">
  <xsl:param name="prev"/>
  <xsl:param name="next"/>
  <xsl:param name="nav.context"/>
  <xsl:param name="content">
    <xsl:apply-imports/>
  </xsl:param>

  <xsl:call-template name="user.preroot"/>

  <html>
    <xsl:call-template name="html.head">
      <xsl:with-param name="prev" select="$prev"/>
      <xsl:with-param name="next" select="$next"/>
    </xsl:call-template>

    <body>
      <xsl:call-template name="body.attributes"/>
      <xsl:call-template name="user.header.navigation"/>

      <xsl:if test="generate-id(.) != generate-id(/*[1])"> <!-- 1. -->
        <xsl:call-template name="header.navigation">
  	<xsl:with-param name="prev" select="$prev"/>
  	<xsl:with-param name="next" select="$next"/>
  	<xsl:with-param name="nav.context" select="$nav.context"/>
        </xsl:call-template>
      </xsl:if>

      <xsl:call-template name="user.header.content"/>

      <xsl:copy-of select="$content"/>

      <xsl:call-template name="user.footer.content"/>

      <xsl:call-template name="footer.navigation">
	<xsl:with-param name="prev" select="$prev"/>
	<xsl:with-param name="next" select="$next"/>
	<xsl:with-param name="nav.context" select="$nav.context"/>
      </xsl:call-template> 

      <xsl:call-template name="user.footer.navigation"/>
    </body>
  </html>
</xsl:template>

<!-- 5. --> 
<xsl:template match="bookinfo" mode="title.markup">
  <xsl:apply-templates select="parent::*" mode="title.markup"/>
</xsl:template>

<!-- 4. -->
<xsl:template match="*" mode="object.title.markup.textonly">
  <xsl:apply-templates select="." mode="title.markup"/>
</xsl:template>

<!-- 2., 3. -->
<xsl:template name="header.navigation">
  <xsl:param name="prev" select="/foo"/>
  <xsl:param name="next" select="/foo"/>
  <xsl:param name="up" select="parent::*"/>
  <xsl:param name="nav.context"/>

  <xsl:variable name="home" select="/*[1]"/>

  <xsl:variable name="row2" select="count($prev) &gt; 0
                                    or (count($up) &gt; 0 
					and generate-id($up) != generate-id($home)
                                        and $navig.showtitles != 0)
                                    or count($next) &gt; 0"/>

  <xsl:if test="$suppress.navigation = '0' and $suppress.header.navigation = '0'">
    <div class="navheader">
      <table width="100%" summary="Navigation header" cellpadding="0" cellspacing="0">
        <tr>
          <th colspan="3" align="center">       <!-- 2. -->
            <xsl:apply-templates select="/book" mode="object.title.markup"/>
          </th>
        </tr>

        <xsl:if test="$row2">
          <tr>
            <td width="20%" align="left">
              <xsl:if test="count($prev)>0">
                <a accesskey="p">
                  <xsl:attribute name="href">
                    <xsl:call-template name="href.target">
                      <xsl:with-param name="object" select="$prev"/>
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="navig.content">
                    <xsl:with-param name="direction" select="'prev'"/>
                  </xsl:call-template>
                </a>
              </xsl:if>
              <xsl:text>&#160;</xsl:text>
            </td>
            <td width="60%" align="center">
              <xsl:choose>                      <!-- 3. -->
                <xsl:when test="count($up) > 0 and contains('preface chapter', local-name($up))
      			  and generate-id($up) != generate-id($home)
                                and $navig.showtitles != 0">
                  <xsl:apply-templates select="$up" mode="object.title.markup"/>
                </xsl:when>
                <xsl:otherwise>&#160;</xsl:otherwise>
              </xsl:choose>
            </td>
            <td width="20%" align="right">
              <xsl:text>&#160;</xsl:text>
              <xsl:if test="count($next)>0">
                <a accesskey="n">
                  <xsl:attribute name="href">
                    <xsl:call-template name="href.target">
                      <xsl:with-param name="object" select="$next"/>
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="navig.content">
                    <xsl:with-param name="direction" select="'next'"/>
                  </xsl:call-template>
                </a>
              </xsl:if>
            </td>
          </tr>
        </xsl:if>
      </table>
    <xsl:if test="$header.rule != 0">
      <hr/>
    </xsl:if>
    </div>
  </xsl:if>
</xsl:template>

<!-- 4., 6. -->
<xsl:template name="footer.navigation">
  <xsl:param name="prev" select="/foo"/>
  <xsl:param name="next" select="/foo"/>
  <xsl:param name="up" select="parent::*"/>
  <xsl:param name="nav.context"/>

  <xsl:variable name="home" select="/*[1]"/>

  <xsl:variable name="row1" select="count($prev) &gt; 0
                                    or count($up) &gt; 0
                                    or count($next) &gt; 0"/>

  <xsl:variable name="row2" select="($prev and $navig.showtitles != 0)
                                    or (generate-id($home) != generate-id(.)
                                        or $nav.context = 'toc')
                                    or ($chunk.tocs.and.lots != 0
                                        and $nav.context != 'toc')
                                    or ($next and $navig.showtitles != 0)"/>

  <xsl:if test="$suppress.navigation = '0' and $suppress.footer.navigation = '0'">
    <div class="navfooter">
      <xsl:if test="$footer.rule != 0">
        <hr/>
      </xsl:if>

      <xsl:if test="$row1 or $row2">
        <table width="100%" summary="Navigation footer" cellspacing="0" cellpadding="0">
          <xsl:if test="$row1">
            <tr>
              <td width="40%" align="left">
                <xsl:if test="count($prev)>0">
                  <a accesskey="p">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$prev"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:call-template name="navig.content">
                      <xsl:with-param name="direction" select="'prev'"/>
                    </xsl:call-template>
                  </a>
                </xsl:if>
                <xsl:text>&#160;</xsl:text>
              </td>
              <td width="20%" align="center">
                <xsl:choose>                 <!-- 6. -->
                  <xsl:when test="$home != . or $nav.context = 'toc'">
                    <a accesskey="h">
                      <xsl:attribute name="href">
                        <xsl:call-template name="href.target">
                          <xsl:with-param name="object" select="$home"/>
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:call-template name="navig.content">
                        <xsl:with-param name="direction" select="'home'"/>
                      </xsl:call-template>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>&#160;</xsl:otherwise>
                </xsl:choose>
                <!-- also omit $chunk.tocs.and.lots != 0 -->
              </td>
              <td width="40%" align="right">
                <xsl:text>&#160;</xsl:text>
                <xsl:if test="count($next)>0">
                  <a accesskey="n">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$next"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:call-template name="navig.content">
                      <xsl:with-param name="direction" select="'next'"/>
                    </xsl:call-template>
                  </a>
                </xsl:if>
              </td>
            </tr>
          </xsl:if>

          <xsl:if test="$row2">
            <tr>
              <td width="40%" align="left" valign="top">
                <xsl:if test="$navig.showtitles != 0">
                  <xsl:apply-templates select="$prev" mode="title.markup"/>
                </xsl:if>
                <xsl:text>&#160;</xsl:text>
              </td>
              <td width="20%" align="center">
                <xsl:choose>                             <!-- 6. -->
                  <xsl:when test="count($up)>0 and generate-id($home) != generate-id($up)
                                               and generate-id($up) != generate-id(/book/bookinfo)">
                    <a accesskey="u">
                      <xsl:attribute name="href">
                        <xsl:call-template name="href.target">
                          <xsl:with-param name="object" select="$up"/>
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:call-template name="navig.content">
                        <xsl:with-param name="direction" select="'up'"/>
                      </xsl:call-template>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>&#160;</xsl:otherwise>
                </xsl:choose>
              </td>
              <td width="40%" align="right" valign="top">
                <xsl:text>&#160;</xsl:text>
                <xsl:if test="$navig.showtitles != 0">
                  <xsl:apply-templates select="$next" mode="title.markup"/>
                </xsl:if>
              </td>
            </tr>
          </xsl:if>
        </table>
      </xsl:if>
    </div>
  </xsl:if>
</xsl:template>




<!-- ==================================================================== -->
<!-- Make LEGALNOTICE an extra-file, omit extra-link on start-page (link
     directly from the original <COPYRIGHT>), and make nav-header/footer: titlepage.xsl -->
<xsl:template match="copyright" mode="titlepage.mode">
  <p class="{name(.)}">
    <a href="{concat('copyright',$html.ext)}">
      <xsl:call-template name="gentext">
        <xsl:with-param name="key" select="'Copyright'"/>
      </xsl:call-template>
    </a>
    <xsl:call-template name="gentext.space"/>
    <xsl:call-template name="dingbat">
      <xsl:with-param name="dingbat">copyright</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="gentext.space"/>
    <xsl:call-template name="copyright.years">
      <xsl:with-param name="years" select="year"/>
      <xsl:with-param name="print.ranges" select="$make.year.ranges"/>
      <xsl:with-param name="single.year.ranges"
                      select="$make.single.year.ranges"/>
    </xsl:call-template>
    <xsl:call-template name="gentext.space"/>
    <xsl:apply-templates select="holder" mode="titlepage.mode"/>
  </p>
</xsl:template>

<!-- Supply information for generate.manifest parameter: manifest.xsl -->
<xsl:template match="legalnotice" mode="enumerate-files">
  <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>
  <xsl:call-template name="make-relative-filename">
    <xsl:with-param name="base.dir">
      <xsl:if test="$manifest.in.base.dir = 0">
        <xsl:value-of select="$base.dir"/>
      </xsl:if>
    </xsl:with-param>
    <xsl:with-param name="base.name" select="concat($id,$html.ext)"/>
  </xsl:call-template>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="legalnotice" mode="titlepage.mode">
  <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>
  <xsl:variable name="filename">
    <xsl:call-template name="make-relative-filename">
      <xsl:with-param name="base.dir" select="$base.dir"/>
      <xsl:with-param name="base.name" select="concat($id,$html.ext)"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="title">
    <xsl:apply-templates select="." mode="title.markup"/>
  </xsl:variable>

  <xsl:call-template name="write.chunk">
    <xsl:with-param name="filename" select="$filename"/>
    <xsl:with-param name="quiet" select="$chunk.quietly"/>
    <xsl:with-param name="content">
      <xsl:call-template name="chunk-element-content">
        <xsl:with-param name="prev" select="/foo"/>
        <xsl:with-param name="next" select="/foo"/>
        <xsl:with-param name="content">
          <xsl:apply-templates mode="titlepage.mode"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:with-param> 
  </xsl:call-template>
</xsl:template>




<!-- ==================================================================== -->
<!-- Authors and Editors in readable font: titlepage.xsl -->
<xsl:template match="author|editor" mode="titlepage.mode">
  <div class="{name(.)}">
    <xsl:call-template name="person.name"/>
    <xsl:apply-templates mode="titlepage.mode" select="./contrib"/>
    <xsl:apply-templates mode="titlepage.mode" select="./affiliation"/>
    <xsl:apply-templates mode="titlepage.mode" select="./email"/>
  </div>
</xsl:template>

<xsl:template match="editor[position()=1]" mode="titlepage.mode">
  <h2 class="editedby"><xsl:call-template name="gentext.edited.by"/></h2>
  <div class="{name(.)}"><xsl:call-template name="person.name"/></div>
</xsl:template>
  
<!-- Notes|important|caution|tip inline. Warnings in table. CSS: admon.xsl -->
<xsl:template name="nongraphical.admonition">
  <div class="{name(.)}">
    <xsl:variable name="label">
      <span class="title" style="font-weight:bold">
        <xsl:call-template name="anchor"/>
        <xsl:if test="$admon.textlabel != 0 or title">
          <xsl:apply-templates select="." mode="object.title.markup"/>
          <xsl:if test="name(.) != 'warning'"><xsl:text>: </xsl:text></xsl:if>
        </xsl:if>
      </span>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="name(.) != 'warning'">
        <xsl:attribute name="style">margin-left: 0.5in; margin-top:1em</xsl:attribute>
        <xsl:copy-of select="$label"/>
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <table class="{name(.)}" width="100%" border="1">
        <tbody><tr><td align="middle"><xsl:copy-of select="$label"/></td></tr>
               <tr><td align="left"><xsl:apply-templates/></td></tr></tbody>
        </table>
      </xsl:otherwise>
    </xsl:choose>

  </div>
</xsl:template>




</xsl:stylesheet>
