import React, { useState, useRef, useEffect, useMemo, useCallback } from 'react'
import { render } from 'react-dom'
import { AgGridReact } from 'ag-grid-react' // the AG Grid React Component
import MyToolPanel from './myToolPanel.jsx'
// import MyStatusPanel from './myStatusPanel.jsx';

import 'ag-grid-community/styles/ag-grid.css' // Core grid CSS, always needed
import 'ag-grid-community/styles/ag-theme-alpine.css' // Optional theme CSS
import ImageRenderer from './ImageRenderer.jsx'

// Core UI & Bootstrap
import '@coreui/coreui/dist/css/coreui.min.css'
import 'bootstrap/dist/css/bootstrap.min.css'
import { CContainer, CRow, CCol, CImage, CFooter, CLink } from '@coreui/react'
import {
  CTable,
  CTableHead,
  CTableRow,
  CTableBody,
  CTableHeaderCell,
  CTableDataCell
} from '@coreui/react'

// MUI since it has some free bits that CoreUI doesn't
import Slider from '@mui/material/Slider'

// Additional components
import { saveAs } from 'file-saver'

// Load our rendered sensor images
let dataDir = './data/'
let imageDir = '/images/' // Should use /public by default?
let imageData = require(dataDir + 'metadata.json')

let previewImage = imageDir + imageData[0].jpegName
let testImage = 'http://stanford.edu/favicon.ico'

// When the user selects a row, we set the data files for possible download
let selectedImage = {
  sensorData: [],
  rgbData: [],
  oi: []
}

var rows
for (let ii = 0; ii < imageData.length; ii++) {
  // Read image objects into grid rows
  // Some visible, some hidden for other uses
  let newRow = [
    {
      // Columns displayed to user
      thumbnail: imageDir + imageData[ii].thumbnailName,
      scene: imageData[ii].scenename,
      lens: imageData[ii].opticsname,
      sensor: imageData[ii].sensorname,

      // Used to set the file for the preview window
      preview: imageDir + imageData[ii].jpegName,

      // Used for download files
      jpegFile: imageData[ii].jpegName,
      sensorRawFile: imageData[ii].sensorRawFile,
      oiFile: imageData[ii].oiFile,

      // Used for other metadata properties
      eTime: imageData[ii].exposureTime,
      aeMethod: imageData[ii].aeMethod
    }
  ]
  if (ii == 0) {
    rows = newRow
  } else {
    rows = rows.concat(newRow)
  }
}

const App = () => {
  const gridRef = useRef()

  // let the grid know which columns and what data to use
  const [rowData] = useState(rows)

  // Each Column Definition results in one Column.
  const [columnDefs, setColumnDefs] = useState([
    {
      headerName: 'Thumbnail',
      width: 128,
      field: 'thumbnail',
      cellRenderer: ImageRenderer
    },
    { headerName: 'Scene', field: 'scene', filter: true },
    { headerName: 'Lens Used', field: 'lens', filter: true },
    { headerName: 'Sensor', field: 'sensor', filter: true },
    // Hidden fields for addtional info
    { headerName: 'Preview', field: 'preview', hide: true },
    { headerName: 'jpegName', field: 'jpegName', hide: true },
    { headerName: 'sensorRawName', field: 'sensorRawFile', hide: true },
    { headerName: 'oiName', field: 'oiFile', hide: true },
    { headerName: 'ExposureTime', field: 'eTime', hide: true },
    { headerName: 'AE-Method', field: 'aeMethod', hide: true }
  ])

  // DefaultColDef sets props common to all Columns
  const defaultColDef = useMemo(() => ({
    sortable: true
  }))

  // This doesn't seem to do anything
  const rowDefs = useState([{ height: 128 }])

  // This either
  const defaultRowDef = useMemo(() => ({
    // height: 400
  }))

  // Example of consuming Grid Event
  const cellClickedListener = useCallback(event => {
    console.log('cellClicked', event)
  }, [])

  // Example of consuming Grid Event
  let pImage
  let pI // This will be the preview image element
  let selectedRow // for use later when we need to download

  const rowClickedListener = useCallback(event => {
    //console.log('cellClicked', event)
    console.log('Row Clicked: \n', event)
    pI = document.getElementById('previewImage')
    //    var pI = React.findDOMNode(this.refs.1);
    pI.src = event.data.preview
    selectedImage.rgbData = event.data.previewImage
    selectedRow = event.data

    // Change preview caption
    var pCaption, eTime, aeMethod
    pCaption = document.getElementById('previewCaption')
    pCaption.textContent = event.data.jpegFile;

    // Update property table
    eTime = document.getElementById('eTime');
    eTime.textContent = event.data.eTime;
    aeMethod = document.getElementById('aeMethod');
    aeMethod.textContent = event.data.aeMethod;
  }, [])
  const sideBar = useMemo(
    () => ({
      toolPanels: [
        'columns',
        'filters',
        {
          id: 'myToolPanel',
          labelDefault: 'My Tool Panel',
          labelKey: 'myToolPanel',
          iconKey: 'filter',
          toolPanel: MyToolPanel
        }
      ],
      defaultToolPanel: 'myToolPanel'
    }),
    []
  )

  // Handle download buttons
  let dlName = ''
  let dlPath = ''
  const buttonDownload = useCallback(event => {
    // Need to figure out which scene & which file
    switch (event.currentTarget.id) {
      case 'dlSensorVolts':
        dlPath = selectedRow.sensorRawFile
        // dlName should be something local!!
        dlName = selectedRow.sensorRawFile
        break
      case 'dlIPRGB': // Working
        dlPath = selectedRow.preview
        dlName = selectedRow.jpegName
        break
      case 'dlOI':
        // Maybe similar, but OI can be very large,
        // so might require something different
        break
      default:
      // Nothing
    }
    console.log(process.env.PUBLIC_URL)
    console.log(dlPath)
    console.log(dlName)
    saveAs(process.env.PUBLIC_URL + dlPath, dlName)
  }, [])

  return (
    <CContainer fluid>
      <CRow>
        <h2>VistaLab's ISET Online Simulator</h2>
        <h4>Stanford University</h4>
        <p>
          Welcome to our Online Camera Simulator. We've used our ISET tools to
          generate a large number of wavelength-dependent scenes, and created
          optical images from them using a number of lenses. Since the
          computation involved can be daunting, we've pre-computed the images
          that are then recorded when using a number of currently-available
          sensors.
        </p>
        <p>
          You can select a scene, a lens, and a sensor, to get a highly-accurate
          simulated image. From there you can download the Voltage response that
          can be used to evaluate your own image processing pipeline, or a JPEG
          with a simple rendering, or the original Optical Image if you want to
          do further analysis on your own.
        </p>
      </CRow>
      <CRow className='align-items-start'>
        <CCol className='align-items-start'>
          <div className='ag-theme-alpine' style={{ width: 800, height: 600 }}>
            <AgGridReact
              ref={gridRef} // Ref for accessing Grid's API
              rowData={rowData} // Row Data for Rows
              columnDefs={columnDefs} // Column Defs for Columns
              defaultColDef={defaultColDef} // Default Column Properties
              animateRows={true} // Optional - set to 'true' to have rows animate when sorted
              rowSelection='single' // Options - allows click selection of rows
              onCellClicked={cellClickedListener} // Optional - registering for Grid Event
              onRowClicked={rowClickedListener} // Optional - registering for Grid Event
            />
          </div>
        </CCol>
        <CCol width={400} height={400}>
          <CRow className='align-items-center'>
            <CImage id='previewImage' rounded thumbnail src={previewImage} />
          </CRow>
          <CRow className='align-items-center'>
            <div id='previewCaption'> No Scene Selected </div>
          </CRow>
          <CRow>
            <Slider>
              aria-label='Exposure Time' defaultValue={0.1}
              valueLabelDisplay='auto' step={0.05}
              marks min={0}
              max={1}
            </Slider>{' '}
          </CRow>
          <CRow className='align-items-center'>Sensor Exposure Time</CRow>
          <CRow>
            <button id='dlSensorVolts' onClick={buttonDownload}>
              Download Sensor Image (volts)
            </button>
          </CRow>
          <CRow>
            <button id='dlIPRGB' onClick={buttonDownload}>
              Download Processed Image (rgb)
            </button>
          </CRow>
          <CRow>
            <button id='dlOI' onClick={buttonDownload}>
              Download Optical Image (large)
            </button>
          </CRow>
          <CRow>
            <CTable>
              <CTableHead>
                <CTableRow>
                  <CTableHeaderCell scope='col'>Property:</CTableHeaderCell>
                  <CTableHeaderCell scope='col'>Value:</CTableHeaderCell>
                </CTableRow>
              </CTableHead>
              <CTableBody id='imageProps'>
                <CTableRow color='primary'>
                  <CTableDataCell>Expsoure:</CTableDataCell>
                  <CTableDataCell id='eTime'>...</CTableDataCell>
                </CTableRow>
                <CTableRow color='secondary'>
                  <CTableDataCell>AE Method</CTableDataCell>
                  <CTableDataCell id='aeMethod'>...</CTableDataCell>
                </CTableRow>
                <CTableRow color='primary'>
                  <CTableDataCell>...</CTableDataCell>
                  <CTableDataCell>...</CTableDataCell>
                </CTableRow>
                <CTableRow color='secondary'>
                  <CTableDataCell>...</CTableDataCell>
                  <CTableDataCell>...</CTableDataCell>
                </CTableRow>
                <CTableRow color='primary'>
                  <CTableDataCell>...</CTableDataCell>
                  <CTableDataCell>...</CTableDataCell>
                </CTableRow>
              </CTableBody>
            </CTable>
          </CRow>
        </CCol>
      </CRow>
      <CFooter>
        <div>
          <span>&copy; 2022 VistaLab, Stanford University</span>
        </div>
        <div>
          <span>...</span>
          <CLink href='https://vistalab.stanford.edu'>VistaLab Team</CLink>
        </div>
      </CFooter>
    </CContainer>
  )
}

export default App
